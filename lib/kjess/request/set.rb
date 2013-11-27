class KJess::Request
  class Set < KJess::Request
    keyword 'SET'
    arity   4
    valid_responses [ KJess::Response::Stored, KJess::Response::NotStored ]

    attr_reader :data

    def parse_options_to_args( opts )
      @data = opts[:data].to_s
      [ opts[:queue_name], 0, opts[:expiration] || 0 , data.bytesize ]
    end

    def protocol_array
      a = super
      a << data
      a << CRLF
    end
  end
end
