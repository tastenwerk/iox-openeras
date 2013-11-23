Rails::Application::Configuration.class_eval do
  def openeras
    @openeras ||= ActiveSupport::OrderedOptions.new
  end
end