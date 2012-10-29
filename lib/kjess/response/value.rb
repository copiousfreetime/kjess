class KJess::Response
  class Value < KJess::Response
    keyword 'VALUE'
    arity    3

    attr_accessor :data

    def queue; args[0]; end
    def flags; args[1].to_i; end
    def bytes; args[2].to_i; end

    # Internal: Read the extra data from the value
    #
    # Read the datablock that is after the value and then the final END marker.
    #
    # Returns nothing
    def read_more( connection )
      read_size  = bytes + CRLF.bytesize
      total_data = connection.read( read_size )
      @data      = total_data[0...bytes]

      line = connection.readline
      resp = KJess::Response.parse( line )
    end
  end
end
