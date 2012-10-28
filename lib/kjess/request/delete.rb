class KJess::Request
  class Delete < KJess::Request
    keyword 'DELETE'
    arity   1
    valid_responses [ KJess::Response::Deleted, KJess::Response::NotFound ]

    def parse_options_to_args( opts )
      [ opts[:queue_name] ]
    end
  end
end
