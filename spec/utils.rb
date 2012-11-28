module KJess
  module Spec
    ROOT = File.expand_path( "..", __FILE__ )
    def self.project_root
      File.expand_path( "..", ROOT )
    end

    def self.memcache_port
      ENV['KJESS_MEMCACHE_PORT'] || 33122
    end

    def self.thrift_port
      ENV['KJESS_THRIFT_PORT'] || 9992
    end

    def self.text_port
      ENV['KJESS_TEXT_PORT'] || 9998
    end

    def self.admin_port
      ENV['KJESS_ADMIN_PORT'] || 9999
    end

    def self.kjess_client
      KJess::Client.new( :port => memcache_port )
    end

    def self.reset_server( client )
      client.flush_all
      qlist = client.stats['queues']
      if qlist then
        qlist.keys.each do |q|
          client.delete( q )
        end
      end
    end
  end
end
