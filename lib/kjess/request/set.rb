class KJess::Request
  class Set < KJess::Request
    keyword 'SET'
    arity   4
    valid_responses [ KJess::Response::Stored, KJess::Response::NotStored ]

    attr_reader :data
    attr_reader :metadata

    def parse_options_to_args( opts )
      @data = opts[:data].to_s
      @metadata = opts[:metadata].to_s
      [ opts[:queue_name], 0, opts[:expiration] || 0 , data.bytesize ]
    end

    def to_protocol
      s = super
      s << data
      s << "#{METADATA_SEPARATOR}#{metadata}" if metadata and metadata.length > 0
      s << CRLF
      s
    end
  end
end
