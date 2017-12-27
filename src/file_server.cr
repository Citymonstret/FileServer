#
# Imports
#
require "yaml"
require "logger"
require "watchbird/dsl"
require "crest"

#
# Init
#
logger = Logger.new(STDOUT)
begin
  if (!File.exists? "settings.yml")
    File.write("settings.yml", Settings.default)
  end
  settings = Settings.from_yaml(File.read "settings.yml")
  # Initialize server
  server = FileServer.new(settings, logger)
rescue exception
  logger.fatal("Caught exception; exiting")
  logger.fatal(exception)
end

# FileServer that listens to file changes and pushes file info a
# rest endpoint
class FileServer
  def initialize(@settings : Settings, @logger : Logger)
    @logger.info("Initialized new FileServer...")
    @settings.directories.each { |directory|
      @logger.info("Adding listener to '#{directory}'")
      watch "#{directory}/*.*" do |e|
        @logger.info "Detected update of type #{e.status} for file #{e.name}"
        Crest.post(@settings.remote_url,
          "payload": {"token" => @settings.token,
                      "type"  => e.status.to_s,
                      "name"  => e.name.to_s,
          })
      end
    }
  end # def initialize
end   # class FileServer

# Basic settings file (settings.yml)
class Settings
  @@default = "
remote_url: 'your_url_here'
token: 'your_token_here'
directories:
    - 'none'
    "

  def self.default
    @@default
  end

  YAML.mapping(
    remote_url: String,
    token: String,
    directories: Array(String)
  )
end
