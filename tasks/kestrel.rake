load 'spec/kestrel_server.rb'

namespace :kestrel do

  directory 'kestrel'
  file KJess::Spec::KestrelServer.zip => 'kestrel' do
    require 'uri'
    require 'net/http'

    url = ::URI.parse("http://robey.github.com/kestrel/download/kestrel-#{KJess::Spec::KestrelServer.erver.version}.zip")

    puts "downloading #{url.to_s} to #{KJess::Spec::KestrelServer.zip} ..."
    File.open( KJess::Spec::KestrelServer.erver.zip, "wb+") do |f|
      res = Net::HTTP.get_response( url )
      f.write( res.body )
    end
  end


  file KJess::Spec::KestrelServer.jar => KJess::Spec::KestrelServer.zip do
    require 'zip'
    puts "extracting #{KJess::Spec::KestrelServer.zip}"
    Zip::ZipFile.open( KJess::Spec::KestrelServer.zip ) do |zipfile|
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
  task :extract => KJess::Spec::KestrelServer.jar

  directory KJess::Spec::KestrelServer.queue_path
  directory KJess::Spec::KestrelServer.log_path

  file KJess::Spec::KestrelServer.config_file => [ KJess::Spec::KestrelServer.jar,
                                                   KJess::Spec::KestrelServer.queue_path,
                                                   KJess::Spec::KestrelServer.log_path ] do
    File.open( KJess::Spec::KestrelServer.config_file, "w+" ) do |f|
      puts "Writing #{KJess::Spec::KestrelServer.config_file}"
      f.write( KJess::Spec::KestrelServer.config_contents )
    end
  end

  task :start => KJess::Spec::KestrelServer.config_file do
    KJess::Spec::KestrelServer.start
  end

  task :stop => KJess::Spec::KestrelServer.config_file do
    KJess::Spec::KestrelServer.stop
  end

  task :status => KJess::Spec::KestrelServer.config_file do
    KJess::Spec::KestrelServer.status
  end

  task :clean do
    FileUtils.rm_rf( KJess::Spec::KestrelServer.dir, :verbose => true )
  end
end

task :clean => 'kestrel:clean'
