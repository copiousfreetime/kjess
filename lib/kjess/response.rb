module KJess
  # Response is the parent class of all Response derived objects that come back
  # from the Kestrel server. It holds the registry of all the Response objects
  # and is responsible for parsing the initial line from the Kestrel server and
  # determinig which Response child object to instantiate.
  class Response < Protocol
    arity 0

    Registry = Hash.new
    def self.registry
      Registry
    end

    # Internal: parse the string and create the appropriate Response child
    # object.
    #
    # str - a String from the Kestrel server
    #
    # Returns a new Response child object
    def self.parse( str )
      keyword, *args = str.strip.split
      klass = Registry.fetch( keyword, KJess::Response::Unknown )
      klass.new( args )
    end

    # Internal: callback to create the @args member
    #
    # opts - the opts that were passed to initialize
    #
    # Returns an Array
    def parse_options_to_args( opts )
      [ opts ].flatten
    end

    # Internal: create the human readable version of this response
    #
    # Returns a String
    def message
      [ keyword, raw_args ].flatten.join(' ')
    end

    # Internal: callback that is used by some Responses that have more complex
    # response creation.
    #
    # connection - the KJess::Connection object to continue to read from
    #
    # Returns nothing
    def read_more( connection ); end

    # Internal: is this Response object an error object.
    #
    # This is overwritte in those objects that create Exceptions
    #
    # Returns false
    def error?
      false
    end
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
require 'kjess/response/reloaded_config'
require 'kjess/response/server_error'
require 'kjess/response/stats'
require 'kjess/response/stored'
require 'kjess/response/unknown'
require 'kjess/response/value'
require 'kjess/response/version'
