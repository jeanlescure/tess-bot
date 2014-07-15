## Chatbot

require 'yaml'
require 'tzinfo'
require 'singleton'
require 'tess/plugins'
require 'tess/connections'
require 'tess/message'
require 'tess/language'
require 'active_support/inflector'
require 'webrick'

module Tess
  class Chatbot
    attr_accessor :config, :connection, :plugins, :hello_messages, :timezone

    def initialize
      $tess_busy = []
      load_config
      load_plugins
      create_connection
      register_plugins
      $server_thread = Thread.new{
        $server_thread[:server] = WEBrick::HTTPServer.new(:Port => 8080, :DocumentRoot => "#{Dir.pwd}/tmp")
        $server_thread[:server].start
      }
    end
    
    def config
      @config
    end

    # Recreate connection with no history loading, so we don't load any
    # messages that may have triggered the exception
    def recover_from_exception
      @disable_history = true
      create_connection
    end

    def connect
      @connection.connect
    end

    def reconnect
      @connection.reconnect
    end

    def join
      @connection.join
      EventMachine::Timer.new(1) do
        say_hello_messages
      end
      rescue => e
        puts "## EXCEPTION in Chatbot join: #{e.message}"
        recover_from_exception
    end

    # Allow plugin to hook in and set @hello_messages
    # Only do the default 'hello' message if no plugins have set hello messages
    def say_hello_messages
      speak "Booyakasha!"
      # @hello_messages.push @config['hello'] if @hello_messages.empty?
      # @hello_messages.each do |hm|
      #   puts "saying hello message: #{hm}"
      #   speak hm
      # end
    end

    def speak(message, type = 'text')
      @connection.yell(message, type)
      rescue => e
        puts "## EXCEPTION in Chatbot speak: #{e.message}"
        recover_from_exception
    end

    def register_plugins
      @connection.register_plugins(@plugins)
    end

    def timer_response
      @connection.timer_response
    end

    def still_connected?
      @connection.still_connected?
    end

    def trap_signals
      [:INT, :TERM].each do |sig|
        trap(sig) do
          speak "Someone's pulling my plug!"
          speak "BRB"
          $server_thread[:server].shutdown
          puts "Trapped signal #{sig.to_s}"
          puts 'Shutting down gracefully'
          # speak @config['goodbye']
          EventMachine::Timer.new(1) { EventMachine.stop_event_loop }
        end
      end
    end

    def run
      connect
      trap_signals
      join

      # am I still connected, bro? Check every 5 seconds
      EventMachine.add_periodic_timer(5) do
        unless still_connected?
          puts 'Disconnected! Reconnecting...'
          reconnect
          trap_signals
          join
        end
      end

      # Time-based plugin timer
      EventMachine.add_periodic_timer(5) do
        timer_response
      end
    end

    private

    def load_config
      config_file = File.join(ROOT_FOLDER, 'config.yml')
      raise 'Tess config.yml file not found' unless File.exists?(config_file)
      @config = YAML.load(File.read(config_file))
      check_config
      @timezone = TZInfo::Timezone.get(@config['timezone'])
    end

    def load_plugins
      @plugins = []
      @config['enabled_plugins'].each do |plugin|
        result = require File.join(File.dirname(__FILE__), "../../plugins/#{plugin.underscore.dasherize}/#{plugin.underscore.dasherize}")
        puts "Require of #{plugin}: #{result}" if ENV['DEBUG']
        begin
          plugin_instance = instance_eval(plugin).new(self)
          @plugins << plugin_instance
        rescue Tess::Plugin::PluginSetupError => e
          puts %Q(Error loading plugin "#{plugin}": #{e})
        end
      end
    end

    # Check config object for required values
    def check_config
      raise 'Timezone missing from config.yml' unless @config['timezone']
    end

    def create_connection
      @hello_messages = []
      @connection = case @config['service']
                    when 'hipchat'
                      if RUBY_PLATFORM =~ /java/
                        Tess::Connections::HipChatJRuby.new(config)
                      else
                        Tess::Connections::HipChatMRI.new(config)
                      end
                    when 'campfire'
                      Tess::Connections::Campfire.new(config)
                    else
                      raise 'Invalid service - please check your config.yml'
                    end
    end
  end
end
