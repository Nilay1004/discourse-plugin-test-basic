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
      def self.prepended(base)
        base.class_eval do
          before_action :reverse_email, only: :create
        end
      end

      def reverse_email
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

  require_dependency 'session_controller'
  ::SessionController.prepend ::ReverseEmailLogin::SessionControllerExtensions
end
