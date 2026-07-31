# frozen_string_literal: true

require_relative "rbase_lti_module/version"
# engine.rb が LtiIframeContext 参照前に lti_iframe_context を自前 require する。二重 require は無害
require_relative "rbase_lti_module/lti_iframe_context"
require_relative "rbase_lti_module/engine"
Dir[File.dirname(__FILE__) + '/LTI/**/*.rb'].each {|file| require_relative file }

module RbaseLtiModule
  class Error < StandardError; end
  # Your code goes here...
  class Railtie < Rails::Railtie
    railtie_name :ecr_lti_module

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/../tasks/*.rake").each { |f| load f }
    end
  end
end
