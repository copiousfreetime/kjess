require 'fcntl'
require 'socket'
require 'resolv'
require 'resolv-replace'

module KJess
  # Connection
  class Connection
    class Error < StandardError; end

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

    # Internal
    #
    # Returns the raw socket. If the socket is not connected it will connect and
    # then return it.
    #
    # Returns a TCPSocket
    def socket
      return @socket if @socket and not @socket.closed?
      return @socket = connect()
    end

    # Internal
    #
    # Create and initialize the internal Socket that is used to connect to the
    # Kestrel Server.
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
    end

    def close
      @socket.close if @socket and not @socket.closed?
      @socket = nil
    end

    def write( msg )
      $stderr.write "--> #{msg}"
      socket.write( msg )
    end

    def readline( eom = Protocol::CRLF )
      line = socket.readline( eom )
      $stderr.write "<-- #{line}"
      return line
    rescue EOFError
      close
      return "EOF"
    end

    def read( *args )
      d = socket.read( *args )
      $stderr.puts "<-- #{d}"
      return d
    end
  end
end
