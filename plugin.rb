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
        login = params[:login]&.strip
        if login.present? && login.include?("@")
          reversed_login = login.reverse
          Rails.logger.info "Original Email: #{login}"
          Rails.logger.info "Reversed Email: #{reversed_login}"
          params[:login] = reversed_login
        end

        super # Call the original create method
      end
    end
  end

  # Ensure the module is loaded
  require_dependency 'session_controller'

  # Prepend the module to extend the SessionController
  ::SessionController.prepend ::ReverseEmailLogin::SessionControllerExtensions
end
