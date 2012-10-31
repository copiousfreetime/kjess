module KJess
  class StatsCache

    attr_reader :last_stat_time
    attr_reader :expiration
    attr_reader :client

    def initialize( client, expiration = 0 )
      @client         = client
      @expiration     = expiration
      @last_stat_time = Time.at( 0 )
      @stats          = nil
    end

    def expiration_time
      last_stat_time + expiration
    end

    def expired?
      Time.now > expiration_time
    end

    def stats
      if expired? then
        @stats = client.stats!
        @last_stat_time = Time.now
      end
      return @stats
    end
  end
end
