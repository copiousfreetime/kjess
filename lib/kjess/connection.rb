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

    CRLF = "\r\n"

    # Public:
    # The hostname/ip address to connect to
    attr_reader :host

    # Public
    # The port number to connect to. Default 22133
    attr_reader :port

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
      @eol             = options[:eol]             || Protocol::CRLF

      @read_buffer = ''
      @socket      = nil
    end

    # Internal: Return the raw socket that is connected to the Kestrel server
    #
    # Returns the raw socket. If the socket is not connected it will connect and
    # then return it.
    #
    # Returns a TCPSocket
    def socket
      return @socket if @socket and not @socket.closed?
      return @socket = connect()
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
      $stderr.write "--> #{msg}" if $DEBUG
      socket.write( msg )
    end

    # Internal: read a single line from the socket
    #
    # eom - the End Of Mesasge delimiter (default: "\r\n")
    #
    # Returns a String
    def readline( read_timeout = nil )
      read_timeout ||= @read_timeout

      deadline = Time.now.to_f + read_timeout

      begin
        while (idx = @read_buffer.index(@eol)) == nil
          timeout = deadline - Time.now.to_f
          if timeout <= 0
            @read_buffer = result + @read_buffer
            raise Timeout, "Could not read from #{host}:#{port}"
          end

          @read_buffer << readpartial(4096, timeout)
        end

        line = @read_buffer.slice!(0, idx + @eol.bytesize)
        $stderr.write "<-- #{line}" if $DEBUG
        retry if line.strip.length == 0
        return line
      end
    rescue EOFError
      close
      return "EOF"
    end

    # Internal: Read from the socket
    #
    # args - this method takes the same arguments as IO#read
    #
    # Returns what IO#read returns
    def read( nbytes, read_timeout = nil )
      read_timeout ||= @read_timeout

      deadline = Time.now.to_f + read_timeout

      result = @read_buffer.slice!(0, nbytes)

      while result.bytesize < nbytes
        timeout = deadline - Time.now.to_f
        if timeout <= 0
          @read_buffer = result + @read_buffer
          raise Timeout, "Could not read from #{host}:#{port}"
        end

        result << readpartial(nbytes - result.bytesize, timeout)
      end

      $stderr.puts "<-- #{result}" if $DEBUG
      return result
    end

    def readpartial(maxlen, timeout = nil )
      timeout ||= @read_timeout

      begin
        socket.read_nonblock(maxlen)
      rescue Errno::EWOULDBLOCK, Errno::EAGAIN
        if IO.select([socket], nil, nil, timeout)
          retry
        else
          raise Timeout, "Could not read from #{host}:#{port} in #{timeout} seconds"
        end
      end
    end
  end
end
