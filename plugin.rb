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

          # Creating a new hash to avoid frozen parameter issues
          new_params = params.permit!.to_h
          new_params[:login] = reversed_email

          # Directly call the original create method with modified parameters
          request.params.merge!(new_params)

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
