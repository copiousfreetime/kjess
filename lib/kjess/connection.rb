require 'fcntl'
require 'socket'
require 'resolv'
require 'resolv-replace'
require 'kjess/error'

module KJess
  # Connection
  class Connection
    class Error < KJess::Error; end
    class Timeout < Error; end

    # Public:
    # The hostname/ip address to connect to
    attr_reader :host

    # Public
    # The port number to connect to. Default 22133
    attr_reader :port

    # Public
    # The timeout for connecting in seconds. Defaults to 2
    attr_accessor :connect_timeout

    # Public
    # The timeout for reading in seconds. Defaults to 2
    attr_accessor :read_timeout

    # Public
    # The timeout for writing in seconds. Defaults to 2
    attr_accessor :write_timeout

    def initialize( host, port = 22133, options = {} )
      if port.is_a?(Hash)
        options = port
        port = 22133
      end

      @host            = host
      @port            = Float( port ).to_i

      @connect_timeout = options[:connect_timeout] || 2
      @read_timeout    = options[:read_timeout]    || 2
      @write_timeout   = options[:write_timeout]   || 2

      @socket         = nil
      @read_buffer    = ''
      @read_deadline  = nil
      @write_deadline = nil
    end

    # Internal: Starts the read timeout deadline for operations
    #
    # timeout - the timeout to set in seconds. This value is added to the
    #           class-wide `read_timeout`
    #
    # Returns nothing
    def with_read_timeout(timeout = nil, &block)
      if @read_deadline
        block.call
      else
        begin
          @current_read_timeout = timeout ? timeout + @read_timeout : @read_timeout
          @read_deadline = Time.now.to_f + @current_read_timeout
          block.call
        ensure
          @current_read_timeout = @read_deadline = nil
        end
      end
    end

    # Internal: Gets the current read timeout
    #
    # Returns an Integer
    def read_timeout_for_deadline
      timeout = @read_deadline ? @read_deadline - Time.now.to_f : @read_timeout
      if timeout <= 0
        raise Timeout, "Could not read from #{host}:#{port} in #{@current_read_timeout} seconds"
      end
      timeout
    end

    # Internal: Starts the write timeout deadline for operations
    #
    # Returns nothing
    def with_write_timeout(&block)
      if @write_deadline
        block.call
      else
        begin
          @write_deadline = Time.now.to_f + @write_timeout
          block.call
        ensure
          @write_deadline = nil
        end
      end
    end

    def write_timeout_for_deadline
      timeout = @write_deadline ? @write_deadline - Time.now.to_f : @write_timeout
      if timeout <= 0
        raise Timeout, "Could not write to #{host}:#{port} in #{@write_timeout} seconds"
      end
      timeout
    end


    # Internal: Return the raw socket that is connected to the Kestrel server
    #
    # Returns the raw socket. If the socket is not connected it will connect and
    # then return it.
    #
    # Returns a TCPSocket
    def socket
      return @socket if @socket and not @socket.closed?
      @socket = connect()
      @read_buffer = ''
      @socket
    end

    # Internal: Create the socket we use to talk to the Kestrel server
    #
    # Returns a TCPSocket
    def connect
      exception = nil

      # Calculate our timeout deadline
      deadline = Time.now.to_f + @connect_timeout

      # Lookup address
      addrs = ::Socket.getaddrinfo(host, nil)

      addrs.each do |addr|
        timeout = deadline - Time.now.to_f
        if timeout <= 0
          raise Timeout, "Could not connect to #{host}:#{port}"
        end

        begin
          sock     = ::Socket.new(addr[4], Socket::SOCK_STREAM, 0)
          sockaddr = ::Socket.pack_sockaddr_in(port, addr[3])

          # close file descriptors if we exec
          sock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

          # Disable Nagle's algorithm
          sock.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)

          begin
            sock.connect_nonblock(sockaddr)
          rescue Errno::EINPROGRESS
            if IO.select(nil, [sock], nil, timeout) == nil
              raise Timeout, "Could not connect to #{host}:#{port}"
            end

            begin
              sock.connect_nonblock(sockaddr)
            rescue Errno::EISCONN
            rescue => ex
              exception = ex
              next
            end
          rescue => ex
            exception = ex
            next
          end

          return sock
        rescue
          sock.close
          raise
        end
      end

      raise Error, "Could not connect to #{host}:#{port}: #{exception.class}: #{exception.message}", exception.backtrace
    end

    # Internal: close the socket if it is not already closed
    #
    # Returns nothing
    def close
      @socket.close if @socket and not @socket.closed?
      @read_buffer = ''
      @socket = nil
    end

    # Internal: is the socket closed
    #
    # Returns true or false
    def closed?
      return true if @socket.nil?
      return true if @socket.closed?
      return false
    end

    # Internal: write the given item to the socket
    #
    # msg - the message to write
    #
    # Returns nothing
    def write( msg )
      with_write_timeout do
        $stderr.puts "--> #{msg}" if $DEBUG

        begin
          until msg.length == 0
            written = socket.syswrite(msg)
            msg = msg[written, msg.size]
          end
        rescue Errno::EWOULDBLOCK, Errno::EINTR, Errno::EAGAIN
          IO.select(nil, [socket], nil, write_timeout_for_deadline)
          retry
        end
      end
    end

    # Internal: read a single line from the socket
    #
    # eom - the End Of Mesasge delimiter (default: "\r\n")
    #
    # Returns a String
    def readline( eom = Protocol::CRLF )
      with_read_timeout do
        while true
          while (idx = @read_buffer.index(eom)) == nil
            readpartial(4096, @read_buffer)
          end

          line = @read_buffer.slice!(0, idx + eom.bytesize)
          $stderr.puts "<-- #{line}" if $DEBUG
          break unless line.strip.length == 0
        end

        return line
      end
    rescue Timeout
      close
      raise
    rescue EOFError
      close
      return "EOF"
    end

    # Internal: Read from the socket
    #
    # args - this method takes the same arguments as IO#read
    #
    # Returns what IO#read returns
    def read( nbytes )
      with_read_timeout do
        while @read_buffer.bytesize < nbytes
          readpartial(nbytes - @read_buffer.bytesize, @read_buffer)
        end

        result = @read_buffer.slice!(0, nbytes)

        $stderr.puts "<-- #{result}" if $DEBUG
        return result
      end
    end

    def readpartial(maxlen, outbuf = nil)
      return socket.sysread(maxlen, outbuf)
    rescue Errno::EWOULDBLOCK, Errno::EAGAIN
      IO.select([socket], nil, nil, read_timeout_for_deadline)
      retry
    end
  end
end
