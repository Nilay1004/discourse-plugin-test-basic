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
    class ReversedEmailAuthenticator < ::Auth::Authenticator
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
        result = Auth::Result.new

        if auth_token[:email].present?
          reversed_email = auth_token[:email].reverse
          Rails.logger.info "Original Email: #{auth_token[:email]}"
          Rails.logger.info "Reversed Email: #{reversed_email}"
          user = User.find_by_email(reversed_email)

          if user
            result.user = user
            result.email = user.email
            result.email_valid = true
          else
            result.failed = true
          end
        else
          result.failed = true
        end

        result
      end
    end

    # Register the custom authenticator
    Auth::Authenticator.register(ReversedEmailAuthenticator.new)
  end
end
