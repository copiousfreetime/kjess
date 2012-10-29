module KJess
  # Request is the base Request Protocol. All Requests made to the Kestrel
  # server are decendants of this class.
  #
  # The Request class holds the registry of all the Request decendent classes.
  class Request < Protocol
    Registry = Hash.new

    def self.registry
      Registry
    end

    def self.valid_responses( list = nil )
      @valid_responses = [ list ].flatten if list
      @valid_responses
    end
  end
end
require 'kjess/response'
require 'kjess/request/flush'
require 'kjess/request/flush_all'
require 'kjess/request/delete'
require 'kjess/request/dump_stats'
require 'kjess/request/get'
require 'kjess/request/quit'
require 'kjess/request/reload'
require 'kjess/request/set'
require 'kjess/request/shutdown'
require 'kjess/request/stats'
require 'kjess/request/status'
require 'kjess/request/version'
