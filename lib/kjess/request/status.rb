class KJess::Request
  # This is not yet in a released version of Kestrel
  class Status < KJess::Request
    keyword 'STATUS'
    arity   1
    #valid_responses [ KJess::Response::Eof ]
  end
end
