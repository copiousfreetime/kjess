class KJess::Response
  class Error < KJess::Response
    keyword 'ERROR'

    def error?
      true
    end

    def exception
      raise KJess::ClientError
    end
  end
end
