class KJess::Response
  class Status < KJess::Response
    class Up < KJess::Response::Status
      keyword "UP"
    end

    class Down < KJess::Response::Status
      keyword "DOWN"
    end

    class Quiescent < KJess::Response::Status
      keyword "QUIESCENT"
    end

    class ReadOnly< KJess::Response::Status
      keyword "READONLY"
    end
  end
end
