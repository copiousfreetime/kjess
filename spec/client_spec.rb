require 'spec_helper'

# $DEBUG = true
describe KJess::Client do
  before do
    @client = KJess::Client.new(:host => '127.0.0.1', :port => 22129)
  end

  after do
    KJess::Spec.reset_server( @client )
  end

  describe "connection" do
    it "knows if it is connected" do
      @client.ping
      @client.connected?.must_equal true
    end

    it "can disconnect and know it is disconnected" do
      @client.ping
      @client.connected?.must_equal true
      @client.disconnect
      @client.connected?.must_equal false
    end
  end

  describe "#version" do
    it "knows the version of the server" do
      @client.version.must_equal "2.3.4"
    end
  end

  describe "#stats" do
    it "can see the stats on an empty server" do
      @client.stats['version'].must_equal '2.3.4'
    end

    it "sees the stats on a server with queues" do
      @client.set( 'stat_q_foo', 'stat_spec_foo' )
      @client.set( 'stat_q_bar', 'stat_spec_bar' )
      @client.stats['queues'].keys.sort.must_equal %w[ stat_q_bar stat_q_foo ]
    end

    it "has an empty queues hash when there are no queues" do
      @client.stats['queues'].size.must_equal 0
    end
  end


  describe "#set" do
    it "adds a item to the server" do
      @client.stats['curr_items'].must_equal 0
      @client.set( 'set_q', "setspec" )
      @client.stats['curr_items'].must_equal 1
    end

    it "a item with an expiration expires" do
      @client.stats['curr_items'].must_equal 0
      @client.set( 'set_q_2', "setspec",  1 )
      @client.stats['curr_items'].must_equal 1
      @client.set( 'set_q_2', "setspec2" )
      @client.stats['curr_items'].must_equal 2
      while s = @client.stats do
        break if s['curr_items'] == 1
      end
      @client.get( 'set_q_2' ).must_equal 'setspec2'
    end

    it 'a really long binary item' do
      binary = (0..255).to_a.pack('c*') * 100
      @client.set 'set_bin_q', binary
      @client.get('set_bin_q').must_equal binary
    end
  end

  describe "#get" do
    it "retrieves a item from queue" do
      @client.set( 'get_q' , "a get item" )
      @client.get( 'get_q' ).must_equal 'a get item'
    end

    it "returns nil if no item is found" do
      @client.get( 'get_q' ).must_be_nil
    end

    it "waits for a period of time and then times out" do
      t1 = Time.now.to_f
      x = @client.get( 'get_q', :wait_for => 100 )
      t2 = Time.now.to_f
      (t2 - t1).must_be :>=, 0.1
      x.must_be_nil
    end

    it "raises an error if peeking and aborting" do
      lambda { @client.get( 'get_q', :peek => true, :abort => true ) }.must_raise KJess::ClientError
    end

    it "raises an error if peeking and opening" do
      lambda { @client.get( 'get_q', :peek => true, :open => true ) }.must_raise KJess::ClientError
    end

    it "raises an error if peeking and closing " do
      lambda { @client.get( 'get_q', :peek => true, :close => true ) }.must_raise KJess::ClientError
    end

    it "raises an error if aborting and opening" do
      lambda { @client.get( 'get_q', :peek => true, :open => true ) }.must_raise KJess::ClientError
    end

    it "raises an error if aborting and closing" do
      lambda { @client.get( 'get_q', :peek => true, :close => true ) }.must_raise KJess::ClientError
    end

    it "raises an error if we attempt to non-tranactionaly get after an open transaction" do
      @client.set( "get_q", "get item 1" )
      @client.set( "get_q", "get item 2" )
      @client.reserve( "get_q" )
      lambda { @client.get( "get_q" ) }.must_raise KJess::Error
    end

  end

  describe "#reserve" do
    it "reserves a item for reliable read" do
      @client.set( 'reserve_q', 'a reserve item' )
      @client.queue_stats( 'reserve_q' )['open_transactions'].must_equal 0
      @client.reserve( 'reserve_q' ).must_equal 'a reserve item'
      @client.queue_stats( 'reserve_q' )['open_transactions'].must_equal 1
    end
  end

  describe "#close_and_reserve" do
    it "reserves an item for reliable read and closes an existing read" do
      @client.set( 'reserve_q', 'a reserve item 1' )
      @client.set( 'reserve_q', 'a reserve item 2' )
      @client.queue_stats( 'reserve_q' )['open_transactions'].must_equal 0

      i1 = @client.reserve( 'reserve_q' )
      i1.must_equal 'a reserve item 1'
      @client.queue_stats( 'reserve_q' )['open_transactions'].must_equal 1

      i2 = @client.close_and_reserve( 'reserve_q' )
      i2.must_equal 'a reserve item 2'

      q_stats = @client.queue_stats('reserve_q')
      q_stats['open_transactions'].must_equal 1
      q_stats['items'].must_equal 0
    end
  end

  describe "#close" do
    it "closes an existing read" do
      @client.set( 'close_q', 'close item 1' )
      @client.queue_stats( 'close_q' )['open_transactions'].must_equal 0
      @client.reserve( 'close_q' )
      @client.queue_stats( 'close_q' )['open_transactions'].must_equal 1
      @client.close( 'close_q' )
      @client.queue_stats( 'close_q' )['items'].must_equal 0
      @client.queue_stats( 'close_q' )['open_transactions'].must_equal 0
    end

    it "does not return a new item from the queue" do
      @client.set( 'close_q', 'close item 1' )
      @client.set( 'close_q', 'close item 2' )
      @client.queue_stats( 'close_q' )['open_transactions'].must_equal 0
      @client.reserve( 'close_q' )
      @client.queue_stats( 'close_q' )['open_transactions'].must_equal 1
      @client.close( 'close_q' )
      @client.queue_stats( 'close_q' )['items'].must_equal 1
      @client.queue_stats( 'close_q' )['open_transactions'].must_equal 0
    end
  end

  describe "#abort" do
    it "aborts a reserved item" do
      @client.set( 'abort_q', 'abort item 1' )
      q_stats = @client.queue_stats('abort_q')
      q_stats['items'].must_equal 1

      @client.reserve( 'abort_q' )
      q_stats = @client.queue_stats('abort_q')
      q_stats['open_transactions'].must_equal 1

      i2 = @client.abort( 'abort_q' )
      q_stats = @client.queue_stats('abort_q')
      q_stats['open_transactions'].must_equal 0
      q_stats['items'].must_equal 1

      i2.must_be_nil
    end
  end

  describe  "#peek" do
    it "looks at a item at the front and does not remove it" do
      @client.stats['curr_items'].must_equal 0
      @client.set( 'peek_q', "peekitem" )
      @client.stats['curr_items'].must_equal 1
      @client.peek('peek_q').must_equal 'peekitem'
      @client.stats['curr_items'].must_equal 1
    end
  end

  describe "#delete" do
    it "deletes a queue" do
      @client.stats['queues'].size.must_equal 0
      @client.set( 'delete_q_1', 'delete me' )
      @client.queue_stats( 'delete_q_1' )['items'].must_equal 1
      @client.delete( 'delete_q_1' )
      @client.queue_stats('delete_q_1').must_be_nil
    end

    it "is okay to delete a queue that does not exist" do
      @client.delete( 'delete_q_does_not_exist' ).must_equal true
    end
  end

  describe "#flush" do
    it "removes all the items from a queue" do
      5.times { |x| @client.set( 'flush_q', "flush_me #{x}" ) }
      @client.queue_stats( 'flush_q' )['items'].must_equal 5
      @client.flush( 'flush_q' )
      @client.queue_stats( 'flush_q' )['items'].must_equal 0
    end

    it "is fine with flushing a non-existant queue" do
      @client.queue_stats( 'flush_q' ).must_be_nil
      @client.flush( 'flush_q' ).must_equal true
      @client.queue_stats( 'flush_q' ).must_be_nil
    end
  end

  describe "#flush_all" do
    it "removes all items from all queues" do
      @client.stats['curr_items'].must_equal 0
      3.times do |qx|
        4.times do |ix|
          @client.set( "flush_all_queue_#{qx}", "item #{qx} #{ix}" )
        end
      end
      @client.stats['queues'].size.must_equal 3
      @client.stats['curr_items'].must_equal 12
      @client.flush_all
      @client.stats['curr_items'].must_equal 0
      @client.stats['queues'].size.must_equal 3
    end
  end

  describe "#reload" do
    it "tells kestrel to reload its config" do
      @client.reload.must_equal true
    end
  end

  describe "#quit" do
    it "disconnects from the server" do
      @client.quit.must_equal true
    end
  end

  describe "#status" do
    it "returns the server status" do
      lambda { @client.status }.must_raise KJess::ClientError
    end
  end

  describe "#ping" do
    it "knows if a server is up" do
      @client.ping.must_equal true
    end
  end

  describe "connecting to a server on a port that isn't listening" do
    it "throws an exception" do
      c = KJess::Connection.new '127.0.0.1', 65521
      lambda { c.socket }.must_raise KJess::Connection::Error
    end
  end

  describe "connecting to a server that isn't responding" do
    it "throws an exception" do
      c = KJess::Connection.new '127.1.1.1', 65521, :timeout => 0.5
      lambda { c.socket }.must_raise KJess::Connection::Timeout
    end
  end
end
