require 'fcntl'
require 'socket'
require 'resolv'
require 'resolv-replace'
require 'kjess/error'

module KJess
  # Connection
  class Connection
    class Error < KJess::Error; end

    CRLF = "\r\n"

    # Public:
    # The hostname/ip address to connect to
    attr_reader :host

    # Public
    # The port number to connect to. Default 22133
    attr_reader :port

    def initialize( host, port = 22133 )
      @host   = host
      @port   = Float( port ).to_i
      @socket = nil
    end

    # Internal: Return the raw socket that is connected to the Kestrel server
    #
    # Returns the raw socket. If the socket is not connected it will connect and
    # then return it.
    #
    # Returns a TCPSocket
    def socket
      close if @pid && @pid != Process.pid
      return @socket if @socket and not @socket.closed?
      @socket = connect()
      @pid = Process.pid
      return @socket
    end

    # Internal: Create the socket we use to talk to the Kestrel server
    #
    # Returns a TCPSocket
    def connect
      sock = TCPSocket.new( host, port )

      # close file descriptors if we exec or something like that
      sock.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

      # Disable Nagle's algorithm
      sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

      # limit only to IPv4?
      # addr = ::Socket.getaddrinfo(host, nil, Socket::AF_INET)
      # sock = ::Socket.new(::Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
      # saddr = ::Socket.pack_sockaddr_in(port, addr[0][3])

      # tcp keepalive
      # :SOL_SOCKET, :SO_KEEPALIVE, :SOL_TCP, :TCP_KEEPIDLE, :TCP_KEEPINTVL, :TCP_KEEPCNT].all?{|c| Socket.const_defined? c}
      # @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE,  true)
      # @sock.setsockopt(Socket::SOL_TCP,    Socket::TCP_KEEPIDLE,  keepalive[:time])
      # @sock.setsockopt(Socket::SOL_TCP,    Socket::TCP_KEEPINTVL, keepalive[:intvl])
      # @sock.setsockopt(Socket::SOL_TCP,    Socket::TCP_KEEPCNT,   keepalive[:probes])
      return sock
    rescue => e
      raise Error, "Could not connect to #{host}:#{port}: #{e.class}: #{e.message}", e.backtrace
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
    rescue => e
      close
      raise Error, "Could not write to #{host}:#{port}: #{e.class}: #{e.message}", e.backtrace
    end

    # Internal: read a single line from the socket
    #
    # eom - the End Of Mesasge delimiter (default: "\r\n")
    #
    # Returns a String
    def readline( eom = Protocol::CRLF )
      while line = socket.readline( eom ) do
        $stderr.write "<-- #{line}" if $DEBUG
        break unless line.strip.length == 0
      end
      return line
    rescue EOFError
      close
      return "EOF"
    rescue => e
      close
      raise Error, "Could not read from #{host}:#{port}: #{e.class}: #{e.message}", e.backtrace
    end

    # Internal: Read from the socket
    #
    # args - this method takes the same arguments as IO#read
    #
    # Returns what IO#read returns
    def read( *args )
      d = socket.read( *args )
      $stderr.puts "<-- #{d}" if $DEBUG
      return d
    rescue => e
      close
      raise Error, "Could not read from #{host}:#{port}: #{e.class}: #{e.message}", e.backtrace
    end
  end
end
