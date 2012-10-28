class KJess::Response
  class DumpedStats < KJess::Response
    keyword 'queue'
    arity    2

    attr_accessor :data

    # Internal: Read the extra data from the value
    #
    # Read the datablock that is after the value and then the final END marker.
    #
    # Returns nothing
    def read_more( connection )
      queue_line_re = /\Aqueue\s+'(\w+)' \{\Z/
      stat_line_re  = /\A(\w+)=(\S+)\Z/
      stats         = Hash.new

      puts message.strip

      md = queue_line_re.match( message.strip )
      return unless md

      current_queue = md.captures.first
      stats[current_queue] = Hash.new

      while line = connection.readline do
        line.strip!
        if md = stat_line_re.match( line ) then
          stats[current_queue][md.captures[0]] = convert_value( md.captures[1] )
        elsif md = queue_line_re.match( line ) then
          current_queue = md.captures.first
          stats[current_queue] = Hash.new
        elsif line == "}" then
          current_queue = nil
        elsif line == "END" then
          break
        end
      end
      @data = stats
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
