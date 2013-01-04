class KJess::Request
  # This is not yet in a released version of Kestrel
  class Status < KJess::Request
    keyword 'STATUS'
    arity   1
    valid_responses [ KJess::Response::Status::Up, KJess::Response::Status::Down,
                      KJess::Response::Status::ReadOnly, KJess::Response::Status::Quiescent,
                      KJess::Response::End ]

    def parse_options_to_args( opts )
      [ opts[:update_to] ]
    end

  end
end
