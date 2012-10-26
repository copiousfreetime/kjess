module KJess
  class Response < Protocol
    arity 0

    Registry = Hash.new
    def self.registry
      Registry
    end
  end
end

require 'kjess/response/client_error'
require 'kjess/response/deleted'
require 'kjess/response/end'
require 'kjess/response/error'
require 'kjess/response/not_found'
require 'kjess/response/not_stored'
require 'kjess/response/server_error'
require 'kjess/response/stored'
require 'kjess/response/value'
require 'kjess/response/version'
