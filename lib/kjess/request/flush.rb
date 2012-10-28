class KJess::Request
  class Flush < KJess::Request
    keyword 'FLUSH'
    arity   1
    valid_responses [ KJess::Response::End ]

    def parse_options_to_args( opts )
      [ opts[:queue_name] ]
    end
  end
end
