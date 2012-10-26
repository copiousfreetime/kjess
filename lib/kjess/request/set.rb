class KJess::Request
  class Set < KJess::Request
    keyword 'SET'
    arity   4
    valid_responses [ KJess::Response::Stored, KJess::Response::NotStored ]

    attr_reader :data

    def parse_options_to_args( opts )
      @data = opts[:data]
      [ opts[:queue], 0, opts[:expiration] || 0 , data.bytesize ]
    end

    def to_protocol
      s = super
      s += "#{data}#{CRLF}"
    end
  end
end
