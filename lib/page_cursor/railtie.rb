module PageCursor
  class Railtie < ::Rails::Railtie
    initializer "page_cursor" do |app|
      ActiveSupport.on_load :action_controller do
        ActionController::Base.include PageCursor::ActionControllerExtension
      end
    end
  end
end
