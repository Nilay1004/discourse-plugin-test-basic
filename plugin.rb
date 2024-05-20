# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.1
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name-darshan"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  require_dependency 'user'

  module ::PIIEncryption
    def self.encrypt_email(email)
      # Log the email before and after encryption
      Rails.logger.info "PIIEncryption: Original email: #{email}"
      encrypted_email = email.reverse
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    end
  end

  class ::User
    after_create :encrypt_email_address

    def encrypt_email_address
      Rails.logger.info "PIIEncryption: Encrypting email for user: #{self.username}"
      self.email = PIIEncryption.encrypt_email(self.email)
      self.save
    end
  end
end
