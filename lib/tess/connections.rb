# Include all files in plugins/ dir

# Dir[File.dirname(__FILE__) + '/connections/*'].each { |file| require file }

require 'tess/connections/base'
require 'tess/connections/campfire'
require 'tess/connections/hipchat'
require 'tess/connections/hipchat-jruby' if RUBY_PLATFORM == 'java'
require 'tess/connections/hipchat-mri' unless RUBY_PLATFORM == 'java'
