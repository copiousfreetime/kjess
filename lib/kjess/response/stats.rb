class KJess::Response
  class Stats < KJess::Response
    keyword 'STAT'
    arity    2

    attr_accessor :data

    # Internal: Read the extra data from the value
    #
    # Read the datablock that is after the value and then the final END marker.
    #
    # Returns nothing
    def read_more( connection )
      stats = Hash.new
      line  = message

      begin
        cmd, raw_key, raw_value = line.strip.split
        case cmd
        when "STAT"
          key        = convert_key( raw_key )
          value      = convert_value( raw_value )
          stats[key] = value
        when "END"
          break
        else
          raise KJess::Error, "Unknown line '#{line.strip}' from STAT command"
        end
      end while line = connection.readline

      @data = stats
    end

    # Internal: conver the line from STATS to a valid key for the stats hash.
    #
    # key - the under_scored key
    #
    # returns the new key
    def convert_key( key )
      key_parts = key.split("_")
      return nil if key_parts.first == "queue" and key_parts.size > 2
      return key
    end

    # Internal: convert the given value to the Integer, Float if it should be.
    #
    # value - the item to convert
    #
    # Returns a Float, Integer or the item itself
    def convert_value( value )
      if value =~ /\A\d+\Z/ then
        Float( value ).to_i
      elsif value =~ /\A\d+\.\d+\Z/
        Float( value )
      else
        value
      end
    end
  end
end
