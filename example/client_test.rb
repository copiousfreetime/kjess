#!/usr/bin/env ruby

require 'kjess'
require 'trollop'
require 'hitimes'

ACTIONS = %w[ produce consume clear status ].sort

options = Trollop::options do
  opt :action,  "Which action to perform (#{ACTIONS.join(', ')})", :default => 'produce'
  opt :qname,  "The name of the queue to use"                    , :default => 'testing'
  opt :count,  "How many messages to produce or consume"         , :default => 1000
  opt :length, "The length of the messages (only for produce)"   , :default => 1024
  opt :host,   "The host to contact"                             , :default => 'localhost'
  opt :port,   "The port number to use"                          , :default => 22133
end

Trollop::die :action, "must be one of #{ACTIONS.join(', ')}" unless ACTIONS.include?( options[:action] )

trap( 'INT' ) do
  puts "Closing down"
  exit
end

class ClientTest
  attr_reader :options
  attr_reader :client
  attr_reader :timer
  attr_reader :item

  def initialize( options )
    @options = options
    @client  = KJess::Client.new( :host => options[:host], :port => options[:port] )
    @timer   = Hitimes::TimedMetric.new( options[:action] )
    @item    = "x" * options[:length]
  end

  def time_and_count( &block )
    options[:count].times do |x|
      timer.measure do
        block.call
      end
    end
    return timer.stats.to_hash
  end

  def produce
    puts "Inserting #{options[:count]} items into the queue at #{options[:host]}:#{options[:port]}"
    time_and_count do
      client.set( options[:qname], item )
    end
  end

  def consume
    puts "Consuming #{options[:count]} items from the queue at #{options[:host]}:#{options[:port]}"
    time_and_count do
      client.get( options[:qname] )
    end
  end

  def run_test
    send( options[:action] )
  end
end

test = ClientTest.new( options )
s = test.run_test
puts s.inspect


