namespace :kestrel do

  def kestrel_version
    ENV['VERSION'] || "2.3.4"
  end

  def kestrel_dir
    File.join( Util.project_root, "kestrel/kestrel-#{kestrel_version}" )
  end

  def kestrel_zip
    "#{kestrel_dir}.zip"
  end

  def kestrel_jar
    File.join( kestrel_dir, "kestrel_2.9.1-#{kestrel_version}.jar" )
  end


  directory 'kestrel'
  file kestrel_zip => 'kestrel' do
    require 'uri'
    require 'net/http'

    url = ::URI.parse("http://robey.github.com/kestrel/download/kestrel-#{kestrel_version}.zip")

    puts "downloading #{url.to_s} to #{kestrel_zip} ..."
    File.open( kestrel_zip, "wb+") do |f|
      res = Net::HTTP.get_response( url )
      f.write( res.body )
    end
  end


  file kestrel_jar => kestrel_zip do
    require 'zip'
    puts "extracting #{kestrel_zip}"
    Zip::ZipFile.open( kestrel_zip ) do |zipfile|
      zipfile.entries.each do |entry|
        next unless entry.file?
        dest_name = File.join('kestrel', entry.name.strip)
        dirname   = File.dirname( dest_name )
        FileUtils.mkdir_p( dirname ) unless File.directory?( dirname )
        entry.extract( dest_name ) { true }
      end
    end
  end

  desc "Unpack kestrel to use for testing"
  task :extract => kestrel_jar

  def kestrel_queue_path
    File.join( kestrel_dir, 'data' )
  end

  def kestrel_log_path
    File.join( kestrel_dir, 'logs' )
  end

  def kestrel_log_file
    File.join( kestrel_log_path, 'kestrel.log' )
  end

  def kestrel_config_file
    File.join( kestrel_dir, 'config', 'kjess.scala' )
  end

  directory kestrel_queue_path
  directory kestrel_log_path

  file kestrel_config_file => [ kestrel_jar, kestrel_queue_path, kestrel_log_path ] do
    File.open( kestrel_config_file, "w+" ) do |f|
      contents = <<_EOC
import com.twitter.conversions.storage._
import com.twitter.conversions.time._
import com.twitter.logging.config._
import com.twitter.ostrich.admin.config._
import net.lag.kestrel.config._

new KestrelConfig {
  listenAddress = "0.0.0.0"
  memcacheListenPort = 22133
  textListenPort = 2222
  thriftListenPort = 2229

  queuePath = "#{kestrel_queue_path}"

  clientTimeout = 30.seconds

  expirationTimerFrequency = 1.second

  maxOpenTransactions = 100

  // default queue settings:
  default.defaultJournalSize = 16.megabytes
  default.maxMemorySize = 128.megabytes
  default.maxJournalSize = 1.gigabyte

  admin.httpPort = 2223

  admin.statsNodes = new StatsConfig {
    reporters = new TimeSeriesCollectorConfig
  }

  loggers = new LoggerConfig {
    level = Level.DEBUG
    handlers = new FileHandlerConfig {
      filename = "#{kestrel_log_file}"
      roll = Policy.Never
    }
  }
}
_EOC
      puts "Writing #{kestrel_config_file}"
      f.write( contents )
    end
  end

  task :start => kestrel_config_file do
    Dir.chdir( kestrel_dir ) do 
      cmd = "java -server -Xmx1024m -Dstage=kjess -jar #{kestrel_jar} &"
      system( cmd )
    end
  end

  task :stop => kestrel_config_file do
    puts %x[ pkill -f #{kestrel_jar} ]
  end

  task :status => kestrel_config_file do
    puts %x[ pgrep -lf #{kestrel_jar} ]
  end

  task :clean do
    FileUtils.rm_rf( kestrel_dir, :verbose => true )
  end
end

task :clean => 'kestrel:clean'
