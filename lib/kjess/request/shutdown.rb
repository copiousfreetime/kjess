class KJess::Request
  class Shutdown < KJess::Request
    keyword 'SHUTDOWN'
    arity   0
    valid_responses [ KJess::Response::Eof ]
  end
end
