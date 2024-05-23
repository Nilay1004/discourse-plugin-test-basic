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
    module SessionControllerExtensions
      def create
        if SiteSetting.reverse_email_login_enabled
          email_or_username = params[:login]&.strip
          if email_or_username.present? && email_or_username.include?("@")
            reversed_email = email_or_username.reverse
            Rails.logger.info "Original Email: #{email_or_username}"
            Rails.logger.info "Reversed Email: #{reversed_email}"

            # Replace the email with the reversed one
            params[:login] = reversed_email
          end
        end

        super # Call the original create method
      end
    end
  end

  require_dependency 'session_controller'
  ::SessionController.prepend ::ReverseEmailLogin::SessionControllerExtensions
end
