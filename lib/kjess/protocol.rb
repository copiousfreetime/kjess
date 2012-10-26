module KJess
  class Protocol

    CRLF = "\r\n"

    class << self
      def keyword( name = nil )
        if name then
          register( name )
          @keyword = name
        end
        @keyword
      end

      def arity( a = nil )
        @arity = a if a
        @arity
      end

      def register( name )
        registry[name] ||= self
      end
    end

    attr_reader :args

    def initialize( opts = {} )
      @args = parse_options_to_args( opts ) || []
    end

    def parse_options_to_args( opts ); end

    def to_protocol
      s = keyword
      s += " #{args.join(' ')}" unless args.empty?
      s += CRLF
    end

    def keyword
      self.class.keyword
    end
  end
end
