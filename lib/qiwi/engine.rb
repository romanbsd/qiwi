require 'rails'
require 'qiwi/server'

module Qiwi
  class Engine < Rails::Engine
    endpoint Qiwi::Server.new
  end
end
