module KJess
  class Response < Protocol
    arity 0

    Registry = Hash.new
    def self.registry
      Registry
    end
  end
end
require 'kjess/response/version'
