class KJess::Request
  class Reload < KJess::Request
    keyword 'RELOAD'
    arity   0
    valid_responses [ KJess::Response::ReloadedConfig ]
  end
end
