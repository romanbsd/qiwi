require 'logger'

module Qiwi

  class Config
    attr_accessor :login, :password, :endpoint, :logger, :transaction_handler

    def logger
      @logger ||= Logger.new(STDERR)
    end
  end

  def self.configure
    yield config
  end

  def self.config
    @config ||= Config.new
  end

end