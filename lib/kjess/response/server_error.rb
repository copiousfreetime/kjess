class KJess::Response
  class ServerError < KJess::Response
    keyword 'SERVER_ERROR'
    arity    1

    def message
      args.join(' ')
    end

    def error?
      true
    end

    def exception
      raise KJess::ServerError, message
    end
  end
end
