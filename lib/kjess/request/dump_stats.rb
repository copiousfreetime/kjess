class KJess::Request
  class DumpStats < KJess::Request
    keyword 'DUMP_STATS'
    arity   0
    valid_responses [ KJess::Response::DumpedStats ]
  end
end
