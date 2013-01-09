module KJess
  # Protocol is the base class that all Kestrel requests and responses are
  # developed on. it defines the DSL for creating the Request and Response
  # objects that make up the Protocol.
  #
  class Protocol

    CRLF = "\r\n"

    class << self
      # Internal: The keyword that starts this protocol message
      #
      # name - the keyword to define this portion of the protocol
      #
      # Returns the name
      def keyword( name = nil )
        @keyword = nil unless defined? @keyword
        if name then
          register( name )
          @keyword = name
        end
        @keyword ||= nil
      end

      # Internal: define or return the arity of this protocol item
      #
      # arity - the number of args this protocol item has
      #
      # Returns the arity
      def arity( a = nil )
        @arity = a if a
        @arity
      end

      # Internal: register this protocol item with its registry
      #
      # name - the name under which to register the protocol
      #
      # Returns nothing
      def register( name )
        registry[name] ||= self
      end
    end

    attr_reader :args
    attr_reader :raw_args

    def initialize( opts = {} )
      @raw_args = opts
      @args = parse_options_to_args( opts ) || []
    end

    # Internal: callback that child classes may use to further parse the
    # initialization arguments
    #
    # Returns Array
    def parse_options_to_args( opts ); end

    # Internal: Convert the object to its protocol serialized format.
    #
    # This may be overridden in child classes
    #
    # Return a String
    def to_protocol
      s = keyword
      s += " #{args.join(' ')}" unless args.empty?
      s += CRLF
    end

    # Internal: return the keyword
    #
    # Returns a String
    def keyword
      self.class.keyword
    end
  end
end
