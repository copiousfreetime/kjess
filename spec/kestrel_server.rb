require 'json'
require 'spec/utils'
require 'net/http'
module KJess::Spec
  class KestrelServer

    class << self
      def version
        "2.3.4"
      end

      def dir
        File.join( KJess::Spec.project_root, "kestrel/kestrel-#{version}" )
      end

      def zip
        "#{dir}.zip"
      end

      def jar
        File.join( dir, "kestrel_2.9.1-#{version}.jar" )
      end

      def queue_path
        File.join( dir, 'data' )
      end

      def log_path
        File.join( dir, 'logs' )
      end

      def log_file
        File.join( log_path, 'kestrel.log' )
      end

      def config_file
        File.join( dir, 'config', 'kjess.scala' )
      end

      def config_contents
      contents = <<_EOC
import com.twitter.conversions.storage._
import com.twitter.conversions.time._
import com.twitter.logging.config._
import com.twitter.ostrich.admin.config._
import net.lag.kestrel.config._

new KestrelConfig {
  listenAddress = "0.0.0.0"
  memcacheListenPort = 22129
  textListenPort = 22298
  thriftListenPort = 22299

  queuePath = "#{KJess::Spec::KestrelServer.queue_path}"

  clientTimeout = 30.seconds

  expirationTimerFrequency = 1.second

  maxOpenTransactions = 100

  // default queue settings:
  default.defaultJournalSize = 16.megabytes
  default.maxMemorySize = 128.megabytes
  default.maxJournalSize = 1.gigabyte

  admin.httpPort = 2230

  admin.statsNodes = new StatsConfig {
    reporters = new TimeSeriesCollectorConfig
  }

  loggers = new LoggerConfig {
    level = Level.DEBUG
    handlers = new FileHandlerConfig {
      filename = "#{KJess::Spec::KestrelServer.log_file}"
      roll = Policy.Never
    }
  }
}
_EOC
      end

      def get_response( path )
        uri = URI.parse( "http://localhost:2230/#{path}" )
        resp = Net::HTTP.get_response( uri )
        JSON.parse( resp.body )
      end

      def start
        Dir.chdir( KJess::Spec::KestrelServer.dir ) do
          cmd = "java -server -Xmx1024m -Dstage=kjess -jar #{KJess::Spec::KestrelServer.jar} &"
          puts cmd
          system( cmd )
          loop do
            break if is_running?
          end
          puts "Started."
        end
      end

      def is_running?
        return "pong" == ping
      rescue Exception => e
        false
      end

      def is_stopped?
        return !is_running?
      end

      def status
        puts "Running" if "pong" == ping
      rescue Exception
        puts "Stopped."
      end

      def stop
        shutdown
        loop do
          break if is_stopped?
        end
        puts "Stopped."
      end

      def ping
        get_response('ping')['response']
      end

      def shutdown
        h = get_response( 'shutdown' )
        return h['response'] == "ok"
      rescue => e
        false
      end
    end

  end
end
