class KJess::Response
  class ServerError < KJess::Response
    keyword 'SERVER_ERROR'
    arity    1

    def message
      args.join(' ')
    end
  end
end
