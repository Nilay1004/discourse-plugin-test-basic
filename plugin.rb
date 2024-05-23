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
        if SiteSetting.plugin_name_enabled
          email = params[:login]&.strip
          if email.present?
            reversed_email = email.reverse
            Rails.logger.info "Original Email: #{email}"
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



  



  
