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
      stat_line_re  = /\ASTAT (\w+) (\S+)\Z/
      stats         = Hash.new

      md = stat_line_re.match( message.strip )
      return unless md

      stats = Hash.new
      stats[md.captures[0]] = md.captures[1]

      while line = connection.readline do
        line.strip!
        if md = stat_line_re.match( line ) then
          next unless key = convert_key( md.captures[0] )

          value      = convert_value( md.captures[1] )
          stats[key] = value
        elsif line == "END" then
          break
        else
          raise KJess::Error, "Unknown line '#{line}' from STAT command"
        end
      end
      @data = stats
    end

    def convert_key( key )
      key_parts = key.split("_")
      return nil if key_parts.first == "queue" and key_parts.size > 2 
      return key
    end

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
