module KJess
  class Response < Protocol
    arity 0

    Registry = Hash.new
    def self.registry
      Registry
    end

    def self.parse( str )
      keyword, *args = str.strip.split
      $stderr.puts "keyword: #{keyword} args: #{args.inspect}"
      klass = Registry.fetch( keyword, KJess::Response::Unknown )
      klass.new( args )
    end

    def parse_options_to_args( opts )
      [ opts ].flatten
    end

    def message
      [ keyword, raw_args ].flatten.join(' ')
    end

    def read_more( connection ); end
  end
end

require 'kjess/response/client_error'
require 'kjess/response/deleted'
require 'kjess/response/dumped_stats'
require 'kjess/response/end'
require 'kjess/response/eof'
require 'kjess/response/error'
require 'kjess/response/flushed_all_queues'
require 'kjess/response/not_found'
require 'kjess/response/not_stored'
require 'kjess/response/server_error'
require 'kjess/response/stored'
require 'kjess/response/stats'
require 'kjess/response/unknown'
require 'kjess/response/value'
require 'kjess/response/version'
