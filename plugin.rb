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
  Rails.logger.info "PIIEncryption: Plugin initialized"

  require_dependency 'user'

  module ::PIIEncryption
    def self.encrypt_email(email)
      Rails.logger.info "PIIEncryption: Encrypting email: #{email}"
      encrypted_email = email.reverse # Simple reversal for demonstration
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      Rails.logger.info "PIIEncryption: Decrypting email: #{encrypted_email}"
      decrypted_email = encrypted_email.reverse
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted_email}"
      decrypted_email
    end
  end

  class ::User
    before_save :encrypt_email_address

    def encrypt_email_address
      Rails.logger.info "PIIEncryption: Encrypting email for user: #{self.username}"
      self.email = PIIEncryption.encrypt_email(self.email)
    end

    # Override the getter for the email attribute
    def email
      encrypted_email = read_attribute(:email)
      PIIEncryption.decrypt_email(encrypted_email)
    end
  end
end
