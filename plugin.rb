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
    class ReversedEmailAuthenticator < ::Auth::DefaultAuthenticator
      def name
        'reversed_email'
      end

      def description
        'Log in with your email address reversed'
      end

      def primary_email_verified?(auth_token)
        true
      end

      def after_authenticate(auth_token)
        email = auth_token[:email]
        username = auth_token[:username]
        if email.present?
          reversed_email = email.reverse
          user = User.find_by(email: reversed_email)
          if user
            auth_result = ::Auth::Result.new
            auth_result.user = user
            auth_result.email = user.email
            auth_result.email_valid = true
            return auth_result
          end
        end
        super(auth_token)
      end
    end

    ::Auth::Authenticator.register_authenticator(::ReverseEmailLogin::ReversedEmailAuthenticator.new)
  end
end
