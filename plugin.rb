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
    class UserAuthenticator
      def self.find_user(login, password)
        return nil if login.blank? || password.blank?

        if SiteSetting.plugin_name_enabled && login.include?("@")
          login = login.reverse
          Rails.logger.info "Reversed Email: #{login}"
        end

        user = User.find_by_email_or_username(login)
        user if user && user.valid_password?(password)
      end
    end

    class Auth::DefaultCurrentUserProvider
      def find_user_by_identifier(email_or_username)
        if SiteSetting.reverse_email_login_enabled && email_or_username.include?("@")
          email_or_username = email_or_username.reverse
          Rails.logger.info "Reversed Email in CurrentUserProvider: #{email_or_username}"
        end
        super(email_or_username)
      end
    end
  end

  # Override the `UserAuthenticator` class
  Auth::DefaultCurrentUserProvider.prepend ::ReverseEmailLogin::UserAuthenticator
end
