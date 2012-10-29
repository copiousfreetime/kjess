require 'spec_helper'

#$DEBUG = true 
describe KJess::Client do
  before do
    @client = KJess::Client.new
  end

  after do
    @client.flush_all
    qlist = @client.stats['queues']
    if qlist then
      qlist.keys.each do |q|
        @client.delete( q )
      end
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
    it "adds a job to the server" do
      @client.stats['curr_items'].must_equal 0
      @client.set( 'set_q', "setspec" )
      @client.stats['curr_items'].must_equal 1
    end

    # it "a job with an expiration expires" do
      # @client.stats['curr_items'].must_equal 0
      # @client.set( 'foo', "setspec",  1 )
      # @client.stats['curr_items'].must_equal 1
      # sleep 1
      # @client.set( 'foo', "setspec2" )
      # @client.stats['curr_items'].must_equal 1
      # @client.get( 'foo' ).must_equal 'setspec2'
    # end
  end

  describe  "#peek" do
    it "looks at a job at the front and does not remove it" do
      @client.stats['curr_items'].must_equal 0
      r = @client.set( 'peek_q', "peekjob" )
      @client.stats['curr_items'].must_equal 1
      @client.peek('peek_q').must_equal 'peekjob'
      @client.stats['curr_items'].must_equal 1
    end
  end

  describe "#delete" do
    it "deletes a queue" do
      @client.stats['queues'].size.must_equal 0
      @client.set( 'delete_q_1', 'delete me' )
      @client.queue_stats( 'delete_q_1' )['items'].must_equal 1
      @client.delete( 'delete_q_1' )
      @client.queue_stats('delete_q_1').must_equal nil
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
      @client.queue_stats( 'flush_q' ).must_equal nil
      @client.flush( 'flush_q' ).must_equal true
      @client.queue_stats( 'flush_q' ).must_equal nil
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
end
