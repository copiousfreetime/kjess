class KJess::Request
  class Stats < KJess::Request
    keyword 'STATS'
    arity   0
    valid_responses [ KJess::Response::Stats ]
  end
end
