# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.1
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 2.7.0


after_initialize do
  module ::ReverseEmailLogin
    module SessionControllerExtensions
      def create
        if params[:login].present? && params[:login].include?("@")
          original_email = params[:login].strip
          reversed_email = original_email.reverse
          Rails.logger.info "Original Email: #{original_email}"
          Rails.logger.info "Reversed Email: #{reversed_email}"

          # Duplication to avoid modifying frozen parameters
          new_params = params.dup
          new_params[:login] = reversed_email

          # Call the original create method with modified params
          @env["action_dispatch.request.parameters"] = new_params
          super()
        else
          super()
        end
      end
    end
  end

  require_dependency 'session_controller'
  ::SessionController.prepend ::ReverseEmailLogin::SessionControllerExtensions
end
