class KJess::Response
  class ClientError < KJess::Response
    keyword 'CLIENT_ERROR'
    arity    1

    def message
      args.join(' ')
    end
  end
end
