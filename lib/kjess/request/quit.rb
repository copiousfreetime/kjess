class KJess::Request
  class Quit < KJess::Request
    keyword 'QUIT'
    arity   0
    valid_responses [ KJess::Response::Eof ]
  end
end
