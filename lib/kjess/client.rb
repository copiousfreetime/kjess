require 'kjess/stats_cache'
module KJess
  class Client
    # Public: The hostname of the kestrel server to connect to
    attr_reader :host

    # Public: The port on hostname of the Kestrel server
    attr_reader :port

    # Public: The admin HTTP Port on the Kestrel server
    attr_reader :admin_port

    # Internal: The cache of stats
    attr_reader :stats_cache

    # Public: The default parameters for a client connection to a Kestrel
    # server.
    def self.defaults
      {
        :host                   => 'localhost',
        :port                   => 22133,
        :admin_port             => 2223,
        :stats_cache_expiration => 0, # number of seconds to keep stats around
      }
    end

    def initialize( opts = {} )
      merged       = Client.defaults.merge( opts )
      @host        = merged[:host]
      @port        = merged[:port]
      @admin_port  = merged[:admin_port]
      @stats_cache = StatsCache.new( self, merged[:stats_cache_expiration] )
      @connection = KJess::Connection.new( host, port )
    end

    # Public: Disconnect from the Kestrel server
    #
    # Returns nothing
    def disconnect
      @connection.close if connected?
      @connection = nil
    end

    # Internal: Allocate or return the existing connection to the server
    #
    # Returns a KJess::Connection
    def connection
      @connection ||= KJess::Connection.new( host, port )
    end

    # Public: is the client connected to a server
    #
    # Returns true or false
    def connected?
      return false if @connection.nil?
      return false if @connection.closed?
      return true
    end

    # Public: Return the version of the Kestrel Server.
    #
    # Return a string
    # Raise Exception if there is a
    def version
      v = KJess::Request::Version.new
      r = send_recv( v )
      return r.version if Response::Version === r
      raise KJess::Error, "Unexpected Response from VERSION command"
    end

    # Public: Add an item to the given queue
    #
    # queue_name - the queue to put an item on
    # item       - the item to put on the queue. #to_s will be called on it.
    # expiration - The number of seconds from now to expire the item
    #
    # Returns true if successful, false otherwise
    def set( queue_name, item, expiration = 0 )
      s = KJess::Request::Set.new( :queue_name => queue_name, :data => item, :expiration => expiration )
      resp = send_recv( s )

      return KJess::Response::Stored === resp
    end

    # Public: Retrieve an item from the given queue
    #
    # queue_name - the name of the queue to retrieve an item from
    # options    - the options for retrieving the items
    #              :wait_for - wait for this many ms for an item on the queued(default: 0)
    #              :open     - count this as an reliable read (default: false)
    #              :close    - close a previous read that was retrieved with :open
    #              :abort    - close an existing read, returning that item to the head of the queue
    #              :peek     - return the first item on the queue, and do not remove it
    #
    # returns a Response
    def get( queue_name, opts = {} )
      opts = opts.merge( :queue_name => queue_name )
      g    = KJess::Request::Get.new( opts )

      if opts[:wait_for]
        wait_for_in_seconds = opts[:wait_for] / 1000
      else
        wait_for_in_seconds = 0.1
      end

      connection.with_additional_read_timeout(wait_for_in_seconds) do
        resp = send_recv( g )
        return resp.data if KJess::Response::Value === resp
        return nil
      end
    end

    # Public: Reserve the next item on the queue
    #
    # This is a helper method to get an item from a queue and open it for
    # reliable read.
    #
    # queue_name - the name of the queue to retrieve an item from
    # options    - Additional options
    #              :wait_for - wait for this many ms for an item on the queue(default: 0)
    def reserve( queue_name, opts = {} )
      opts = opts.merge( :open => true )
      get( queue_name, opts )
    end

    # Public: Reserve the next item on the queue and close out the previous
    # read.
    #
    # This is a helper method to do a reliable read on a queue item while
    # closing out the existing read at the same time.
    #
    # queue_name - the name of the quee to retieve and item from
    # options    - Additional options
    #              :wait_for - wait for this many ms for an item on the queue(default: 0)
    def close_and_reserve( queue_name, opts = {} )
      opts = opts.merge( :close => true )
      reserve( queue_name, opts )
    end

    # Public: Peek at the top item in the queue
    #
    # queue_name - the name of the queue to retrieve an item from
    #
    # Returns a Response
    def peek( queue_name )
      get( queue_name, :peek => true )
    end

    # Public: Close an existing reliable read
    #
    # queue_name - the name of the queue to abort
    #
    # Returns a Response
    def close( queue_name )
      get( queue_name, :close => true )
    end


    # Public: Abort an existing reliable read
    #
    # queue_name - the name of the queue to abort
    #
    # Returns a Response
    def abort( queue_name )
      get( queue_name, :abort => true )
    end

    # Public : Remove a queue from the kestrel server
    #
    # This will remove any queue you want. Including queues that do not exist.
    #
    # queue_name - the name of the queue to remove
    #
    # Returns true if it was deleted false otherwise
    def delete( queue_name )
      req  = KJess::Request::Delete.new( :queue_name => queue_name )
      resp = send_recv( req )
      return KJess::Response::Deleted === resp
    end

    # Public: Remove all items from a queue on the kestrel server
    #
    # This will flush any and all queue. Even queues that do not exist.
    #
    # queue_name - the name of the queue to flush
    #
    # Returns true if the queue was flushed.
    def flush( queue_name )
      # It can take a long time to flush all of the messages
      # on a server, so we'll set the read timeout to something
      # much higher than usual.
      connection.with_additional_read_timeout(60) do
        req  = KJess::Request::Flush.new( :queue_name => queue_name )
        resp = send_recv( req )
        return KJess::Response::End === resp
      end
    end

    # Public: Remove all items from all queues on the kestrel server
    #
    # Returns true.
    def flush_all
      # It can take a long time to flush all of the messages
      # on a server, so we'll set the read timeout to something
      # much higher than usual.
      connection.with_additional_read_timeout(60) do
        resp = send_recv( KJess::Request::FlushAll.new )
        return KJess::Response::End === resp
      end
    end

    # Public: Have Kestrel reload its config.
    #
    # Currently the kestrel server will say that the config was reloaded no
    # matter what so there is no way to determine if the config failed to load.
    #
    # Returns true
    def reload
      resp = send_recv( KJess::Request::Reload.new )
      return KJess::Response::ReloadedConfig === resp
    end

    # Public: Disconnect from the kestrel server.
    #
    # Returns true
    def quit
      resp = send_recv( KJess::Request::Quit.new )
      return KJess::Response::Eof === resp
    end

    # Public: Return the server status.
    #
    # Currently this is only supported in the HEAD versin of kestrel. Version
    # where this is not available will raise ServerError.
    #
    # Returns a String.
    def status( update_to = nil )
      resp = send_recv( KJess::Request::Status.new( update_to ) )
      raise KJess::Error, "Status command is not supported" if KJess::Response::ClientError === resp
      return resp.message
    end

    # Public: Return stats about the Kestrel server, they will be cached
    # according to the stats_cache_expiration initialization parameter
    #
    # Returns a Hash
    def stats
      stats_cache.stats
    end

    # Internal: Return the hash of stats
    #
    # Using a combination of the STATS and DUMP_STATS commands this generates a
    # good overview of all the most used stats for a Kestrel server.
    #
    # Returns a Hash
    def stats!
      stats       = send_recv( KJess::Request::Stats.new )
      raise KJess::Error, "Problem receiving stats: #{stats.inspect}" unless KJess::Response::Stats === stats

      h           = stats.data
      dump_stats  = send_recv( KJess::Request::DumpStats.new )
      h['queues'] = Hash.new
      if KJess::Response::DumpedStats === dump_stats then
        h['queues'].merge!( dump_stats.data )
      end
      return h
    end

    # Public: Returns true if the server is alive
    #
    # This uses the 'stats' method to see if the server is alive
    #
    # Returns true or false
    def ping
      stats
      true
    rescue Errno::ECONNREFUSED => e
      puts e
      false
    end

    # Public: Return just the stats about a particular queue
    #
    # Returns a Hash
    def queue_stats( queue_name )
      stats['queues'][queue_name]
    end

    # Public: Tells the Kestrel server to shutdown
    #
    # Returns nothing
    def shutdown
      send_recv( KJess::Request::Shutdown.new )
    end

    # Internal: Send and recive a request/response
    #
    # request - the Request objec to send to the server
    #
    # Returns a Response object
    def send_recv( request )
      connection.write( request.to_protocol )
      line = connection.readline
      resp = KJess::Response.parse( line )
      resp.read_more( connection )
      raise resp if resp.error?
      return resp
    end
  end
end
