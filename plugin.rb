# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.1
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 2.7.0

after_initialize do
  class ::ReverseEmailMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.path == "/session" && request.post? && request.params["login"]&.include?("@")
        original_email = request.params["login"].strip
        reversed_email = original_email.reverse
        Rails.logger.info "Original Email: #{original_email}"
        Rails.logger.info "Reversed Email: #{reversed_email}"
        request.update_param("login", reversed_email)
      end

      @app.call(env)
    end
  end

  Rails.application.config.middleware.use ::ReverseEmailMiddleware
end
