require 'qiwi/config'
require 'qiwi/client'
require 'qiwi/engine' if defined?(Rails)

module Qiwi
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip.freeze

  def self.logger
    config.logger
  end
end
