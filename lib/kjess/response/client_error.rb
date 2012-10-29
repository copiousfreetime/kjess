require 'kjess/error'
class KJess::Response
  class ClientError < KJess::Response
    keyword 'CLIENT_ERROR'
    arity    1

    def message
      args.join(' ')
    end

    def error?
      true
    end

    def exception
      KJess::ClientError.new( message )
    end
  end
end
