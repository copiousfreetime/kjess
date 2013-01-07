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

    # TODO: make port an option at next major version number change
    def initialize( host, port = 22133, options = {} )
      if port.is_a?(Hash)
        options = port
        port = 22133
      end

      @host            = host
      @port            = Float( port ).to_i

      @connect_timeout = options.fetch(:connect_timeout, 2)
      @read_timeout    = options.fetch(:read_timeout   , 2)
      @write_timeout   = options.fetch(:write_timeout  , 2)

      @keepalive_active   = options.fetch(:keepalive_active, true)
      @keepalive_time     = options.fetch(:keepalive_time    , 60)
      @keepalive_interval = options.fetch(:keepalive_interval, 30)
      @keepalive_probes   = options.fetch(:keepalive_probes,    5)

      @socket          = nil
      @pid             = nil
      @read_buffer     = ''
    end

    # Internal: Adds time to the read timeout
    #
    # additional_timeout - additional number of seconds to the read timeout
    #
    # Returns nothing
    def with_additional_read_timeout(additional_timeout, &block)
      old_read_timeout, @read_timeout = @read_timeout, @read_timeout + additional_timeout
      block.call
    ensure
      @read_timeout = old_read_timeout
    end

    # Internal: Return the raw socket that is connected to the Kestrel server
    #
    # Returns the raw socket. If the socket is not connected it will connect and
    # then return it.
    #
    # Make sure that we close the socket if we are not the same process that
    # opened that socket to begin with.
    #
    # Returns a TCPSocket
    def socket
      close if @pid && @pid != Process.pid
      return @socket if @socket and not @socket.closed?
      @socket      = connect()
      @pid         = Process.pid
      @read_buffer = ''
      return @socket
    end

    # Internal: Low level socket allocation and option configuration
    #
    # Returns a new Socket instance
    def blank_socket
      sock = ::Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)

      # close file descriptors if we exec
      sock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

      # Disable Nagle's algorithm
      sock.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, 1)

      if using_keepalive? then
        sock.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE , true )
        sock.setsockopt( Socket::SOL_TCP,    Socket::TCP_KEEPIDLE , keepalive_idle )
        sock.setsockopt( Socket::SOL_TCP,    Socket::TCP_KEEPINTVL, keepalive_interval)
        sock.setsockopt( Socket::SOL_TCP,    Socket::TCP_KEEPCNT  , keepalive_count)
      end

      return sock

    end

    # Internal: say if we are using TCP Keep Alive or not
    #
    # We will return true if the initialization options :keepalive_active is
    # set to true, and if all the constants that are necessary to use TCP keep
    # alive are defined.
    #
    # It may be the case that on some operating systems that the constants are
    # not defined, so in that case we do not want to attempt to use tcp keep
    # alive if we are unable to do so in any case.
    #
    # Returns true or false
    def using_keepalive?
      using = false
      if @keepalive_active then
        using = [ :SOL_SOCKET, :SO_KEEPALIVE, :SOL_TCP, :TCP_KEEPIDLE, :TCP_KEEPINTVL, :TCP_KEEPCNT].all? do |c|
          Socket.const_defined? c
        end
      end
      return using
    end
    # Internal: Create the socket we use to talk to the Kestrel server
    #
    # Returns a Socket
    def connect
      exception = nil

      # Calculate our timeout deadline
      deadline = Time.now.to_f + @connect_timeout

      # Lookup address, we only want           IPv4 , TCP
      addrs = ::Socket.getaddrinfo(host, port, ::Socket::AF_INET, ::Socket::SOCK_STREAM )

      addrs.each do |addr|
        timeout = deadline - Time.now.to_f
        raise Timeout, "Could not connect to #{host}:#{port}" unless timeout > 0
        sockaddr = ::Socket.pack_sockaddr_in(addr[1], addr[3])
        sock     = blank_socket()

        begin
          begin
            sock.connect_nonblock( sockaddr )
          rescue Errno::EINPROGRESS
            if IO.select(nil, [sock], nil, timeout) == nil
              raise Timeout, "Could not connect to #{host}:#{port}"
            end

            begin
              sock.connect_nonblock( sockaddr )
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
      $stderr.puts "--> #{msg}" if $DEBUG

      begin
        until msg.length == 0
          written = socket.write_nonblock(msg)
          msg = msg[written, msg.length]
        end
      rescue Errno::EWOULDBLOCK, Errno::EINTR, Errno::EAGAIN, Errno::ECONNRESET
        if IO.select(nil, [socket], nil, @write_timeout)
          retry
        else
          raise Timeout, "Could not write to #{host}:#{port} in #{@write_timeout} seconds"
        end
      end
    rescue Timeout
      close
      raise
    end

    # Internal: read a single line from the socket
    #
    # eom - the End Of Mesasge delimiter (default: "\r\n")
    #
    # Returns a String
    def readline( eom = Protocol::CRLF )
      while true
        while (idx = @read_buffer.index(eom)) == nil
          @read_buffer << readpartial(10240)
        end

        line = @read_buffer.slice!(0, idx + eom.length)
        $stderr.puts "<-- #{line}" if $DEBUG
        break unless line.strip.length == 0
      end

      return line
    rescue Timeout
      close
      raise
    rescue EOFError
      close
      return "EOF"
    rescue => e
      close
      raise Error, "Could not read from #{host}:#{port}: #{e.class}: #{e.message}", e.backtrace
    end

    # Internal: Read from the socket
    #
    # nbytes - this method takes the number of bytes to read
    #
    # Returns what IO#read returns
    def read( nbytes )
      while @read_buffer.length < nbytes
        @read_buffer << readpartial(nbytes - @read_buffer.length)
      end

      result = @read_buffer.slice!(0, nbytes)

      $stderr.puts "<-- #{result}" if $DEBUG
      return result
    rescue Timeout
      close
      raise
    end

    def readpartial(maxlen, outbuf = nil)
      return socket.read_nonblock(maxlen, outbuf)
    rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::ECONNRESET
      if IO.select([socket], nil, nil, @read_timeout)
        retry
      else
        raise Timeout, "Could not read from #{host}:#{port} in #{@read_timeout} seconds"
      end
    end
  end
end
