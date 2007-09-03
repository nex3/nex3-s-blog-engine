ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run {}

# Adding this so it doesn't break on my remote host.
# I have no idea why it's necessary.
class ActionController::AbstractRequest
  alias_method :old_method, :method
  def method
    @env['REQUEST_METHOD'] ||= 'get'
    old_method
  end
end
