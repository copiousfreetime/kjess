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
      raise Response::Error, r
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
    # queue_name - the name of the queue to remove
    #
    # Returns true if it was deleted false otherwise
    def delete( queue_name )
      d = KJess::Request::Delete.new( :queue_name => queue_name )
      send_recv( d )
    end

    def flush( queue_name )
      d = KJess::Request::Flush.new( :queue_name => queue_name )
      send_recv( d )
    end

    def flush_all
      send_recv( KJess::Request::FlushAll.new )
    end

    def reload
      send_recv( KJess::Request::Reload.new )
    end

    def quit
      send_recv( KJess::Request::Quit.new )
    end

    # using a combination of stats and dump_stats for ease of parsing
    def stats
      stats = send_recv( KJess::Request::Stats.new )
      dump_stats = send_recv( KJess::Request::DumpStats.new )
      h = stats.data
      h['queues'] = dump_stats.data
      return h
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
