require 'fcntl'
require 'resolv'
require 'resolv-replace'
require 'kjess/error'
require 'kjess/socket'

module KJess
  # Connection
  class Connection
    class Error < KJess::Error; end

    # Public: Set a socket factory -- an object responding
    # to #call(options) that returns a Socket object
    def self.socket_factory=(factory)
      @socket_factory = factory
    end

    # Public: Return a socket factory
    def self.socket_factory
      @socket_factory || proc { |options| Socket.connect(@options) }
    end

    # Public: The hostname/ip address to connect to.
    def host
      socket.host
    end

    # Public: The port number to connect to. Default 22133
    def port
      socket.port
    end

    # Public: The timeout for connecting in seconds. Defaults to 2
    def connect_timeout
      socket.connect_timeout
    end

    # Public: The timeout for reading in seconds. Defaults to 2
    def read_timeout
      socket.read_timeout
    end

    # Public: The timeout for writing in seconds. Defaults to 2
    def write_timeout
      socket.write_timeout
    end

    # Internal: return thekeepalive timeout
    def keepalive_active?
      socket.keepalive_active?
    end

    # Internal: return the keepalive count
    # The keepalive count
    def keepalive_count
      socket.keepalive_count
    end

    # Internal: return the keepalive interval
    def keepalive_interval
      socket.keepalive_interval
    end

    # Internal: return the keepalive idle
    def keepalive_idle
      socket.keepalive_idle
    end

    # TODO: make port an option at next major version number change
    def initialize( host, port = 22133, options = {} )
      if port.is_a?(Hash)
        options = port
        port = 22133
      end

      @options         = options.dup
      @options[:host] = host
      @options[:port] = Float( port ).to_i
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
      old_read_timeout = socket.read_timeout
      socket.read_timeout += additional_timeout
      block.call
    ensure
      @read_timeout = old_read_timeout
    end

    # Internal: Return the socket that is connected to the Kestrel server
    #
    # Returns the socket. If the socket is not connected it will connect and
    # then return it.
    #
    # Make sure that we close the socket if we are not the same process that
    # opened that socket to begin with.
    #
    # Returns a KJess::Socket
    def socket
      close if @pid && @pid != Process.pid
      return @socket if @socket and not @socket.closed?
      @socket      = self.class.socket_factory.call(@options)
      @pid         = Process.pid
      @read_buffer = ''
      return @socket
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
      socket.write( msg )
    rescue KJess::Error
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
          @read_buffer << socket.readpartial(10240)
        end

        line = @read_buffer.slice!(0, idx + eom.length)
        $stderr.puts "<-- #{line}" if $DEBUG
        break unless line.strip.length == 0
      end
      return line
    rescue KJess::Error
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
        @read_buffer << socket.readpartial(nbytes - @read_buffer.length)
      end

      result = @read_buffer.slice!(0, nbytes)

      $stderr.puts "<-- #{result}" if $DEBUG
      return result
    rescue KJess::Error
      close
      raise
    end
  end
end
