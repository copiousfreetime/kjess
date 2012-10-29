module KJess
  class Client
    # Public: The hostname of the kestrel server to connect to
    attr_reader :host

    # Public: The port on hostname of the Kestrel server
    attr_reader :port

    # Public: The admin HTTP Port on the Kestrel server
    attr_reader :admin_port

    # Internal: The KJess::Connection to the kestrel server
    attr_reader :connection

    # Public: The default parameters for a client connection to a Kestrel
    # server.
    def self.defaults
      {
        :host       => 'localhost',
        :port       => 22133,
        :admin_port => 2223
      }
    end

    def initialize( opts = {} )
      merged      = Client.defaults.merge( opts )
      @host       = merged[:host]
      @port       = merged[:port]
      @admin_port = merged[:admin_port]
      @connection = KJess::Connection.new( host, port )
    end

    # Public: Return the version of the Kestrel Server.
    #
    # Return a string
    # Raise Exception if there is a
    def version
      v = KJess::Request::Version.new
      r = send_recv( v )
      return r.version if Response::Version === r
      raise "WTF"
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
      send_recv( s )
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
      resp = send_recv( g )

      return resp.data if KJess::Response::Value === resp
      return nil
    end

    # Public: Peek at the top item in the queue
    #
    # queue_name - the name of the queue to retrieve an item from
    #
    # Returns a Response
    def peek( queue_name )
      get( queue_name, :peek => true )
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
      req  = KJess::Request::Flush.new( :queue_name => queue_name )
      resp = send_recv( req )
      return KJess::Response::End === resp
    end

    # Public: Remove all items from all queues on the kestrel server
    #
    # Returns true.
    def flush_all
      resp = send_recv( KJess::Request::FlushAll.new )
      return KJess::Response::End === resp
    end

    def reload
      send_recv( KJess::Request::Reload.new )
    end

    def quit
      send_recv( KJess::Request::Quit.new )
    end

    def status( update_to = nil )
      send_recv( KJess::Request::Status.new( update_to ) )
    end

    # Public: Return stats about the Kestrel server
    #
    # Using a combination of the STATS and DUMP_STATS commands this generates a
    # good overview of all the most used stats for a Kestrel server.
    #
    # Returns a Hash
    def stats
      stats       = send_recv( KJess::Request::Stats.new )
      h           = stats.data
      dump_stats  = send_recv( KJess::Request::DumpStats.new )
      h['queues'] = Hash.new
      if KJess::Response::DumpedStats === dump_stats then
        h['queues'].merge!( dump_stats.data )
      end
      return h
    end

    # Public: Return just the stats about a particular queue
    #
    # Returns a Hash
    def queue_stats( queue_name )
      stats['queues'][queue_name]
    end

    def shutdown
      send_recv( KJess::Request::Shutdown.new )
    end

    def send_recv( request )
      connection.write( request.to_protocol )
      line = connection.readline
      resp = KJess::Response.parse( line )
      resp.read_more( connection )
      return resp
    end
  end
end
