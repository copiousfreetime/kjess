module KJess
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
require 'kjess/request/set'
require 'kjess/request/version'
