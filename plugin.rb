# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.1
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

after_initialize do
  module ::ReverseEmailLogin
    class ReverseEmailMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if SiteSetting.reverse_email_login_enabled
          request = Rack::Request.new(env)
          if request.path == "/session" && request.post?
            email = request.params["login"]&.strip
            if email&.include?("@")
              reversed_email = email.reverse
              Rails.logger.info "Original Email: #{email}"
              Rails.logger.info "Reversed Email: #{reversed_email}"
              request.update_param("login", reversed_email)
            end
          end
        end
        @app.call(env)
      end
    end
  end

  # Register the middleware
  Discourse::Application.config.middleware.insert_before ActionDispatch::Cookies, ::ReverseEmailLogin::ReverseEmailMiddleware
end
