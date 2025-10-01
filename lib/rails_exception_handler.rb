require 'net/http'

require 'rails_exception_handler/configuration'
require 'rails_exception_handler/handler'
require 'rails_exception_handler/parser'
require 'rails_exception_handler/storage'
require 'rails_exception_handler/engine'
require 'rails_exception_handler/catcher'
require 'rails_exception_handler/fake_session'

module RailsExceptionHandler
  class Middleware
    def initialize(app)
      @app = app
    end
  
    def call(env)
      @app.call(env)
    rescue Exception => e
      raise e unless RailsExceptionHandler.configuration.activate?
      Handler.new(env, e).handle_exception
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
    return unless configuration.activate?

    unless Rails.configuration.middleware.class == ActionDispatch::MiddlewareStack && Rails.configuration.middleware.include?(Middleware)
      Rails.configuration.middleware.use(Middleware)
    end


    Rails.configuration.action_dispatch.show_exceptions = if Rails::VERSION::MAJOR < 7 || (Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR == 0)
      true
    else
      :all
    end
    Rails.configuration.consider_all_requests_local = false
    require File.expand_path(File.dirname(__FILE__)) + '/patch/show_exceptions'
    configuration.run_callback
  end
end

class RailsExceptionHandler::ActiveRecord
end
class RailsExceptionHandler::Mongoid
end

