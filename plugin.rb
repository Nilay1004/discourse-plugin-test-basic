# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.1
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 2.7.0

enabled_site_setting :reverse_email_login_enabled

after_initialize do
  module ::ReverseEmailLogin
    module DefaultCurrentUserProviderExtensions
      def find_user_by_identifier(email_or_username)
        if SiteSetting.reverse_email_login_enabled && email_or_username.include?("@")
          email_or_username = email_or_username.reverse
          Rails.logger.info "Reversed Email in CurrentUserProvider: #{email_or_username}"
        end
        super(email_or_username)
      end
    end
  end

  # Ensure the module is loaded
  require_dependency 'auth/default_current_user_provider'

  # Prepend the module
  Auth::DefaultCurrentUserProvider.prepend ::ReverseEmailLogin::DefaultCurrentUserProviderExtensions
end
