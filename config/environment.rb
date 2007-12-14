ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.1' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run { |config| config.action_controller.session_store = :active_record_store }

# Adding this so it doesn't break on my remote host.
# I have no idea why it's necessary.
class ActionController::AbstractRequest
  alias_method :old_method, :method
  def method
    @env['REQUEST_METHOD'] ||= 'get'
    old_method
  end
end

module Nex3
  conf_loc = File.join(RAILS_ROOT, "config", "nex3.yml")
  unless File.exists?(conf_loc)
    Config = {}
  else
    Config = YAML.load(File.read(conf_loc))
  end

  if akismet = Config['akismet']
    Akismet = ::Akismet.new(akismet['apikey'], akismet['blog'])
  else
    class Fakismet < ::Akismet
      def initialize; super("", ""); end
      def callAkismet(*whatever); false; end
    end

    Akismet = Fakismet.new
  end
end

%w{codecloth syntax/lisp syntax/javascript}.each(&method(:require))
