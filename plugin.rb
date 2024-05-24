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
    module ApplicationControllerExtensions
      def handle_login_params
        if params[:login]&.include?("@")
          original_email = params[:login].strip
          reversed_email = original_email.reverse
          Rails.logger.info "Original Email: #{original_email}"
          Rails.logger.info "Reversed Email: #{reversed_email}"
          params[:login] = reversed_email
        end
      end
    end
  end

  # Ensure the module is loaded
  require_dependency 'application_controller'
  
  # Prepend the module to extend the ApplicationController
  ::ApplicationController.prepend ::ReverseEmailLogin::ApplicationControllerExtensions

  # Add a before_action to intercept the login params before the session controller processes them
  ::ApplicationController.class_eval do
    before_action :handle_login_params, only: [:create]
  end
end
