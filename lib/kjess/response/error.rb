class KJess::Response
  class Error < KJess::Response
    keyword 'ERROR'

    def error?
      true
    end

    def exception
      raise KJess::Error
    end
  end
end
