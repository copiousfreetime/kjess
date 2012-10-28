class KJess::Request
  class FlushAll < KJess::Request
    keyword 'FLUSH_ALL'
    arity    0
    valid_responses [ KJess::Response::FlushedAllQueues ]
  end
end
