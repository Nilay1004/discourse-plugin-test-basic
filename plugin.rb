# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.3
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 3.0.0

enabled_site_setting :plugin_name_enabled

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name-darshan"
end

require_relative "lib/my_plugin_module/engine"

# Plugin initialization and configuration
after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  require_dependency 'user'

  module ::PIIEncryption
    def self.encrypt_email(email)
      # Your encryption logic here
      encrypted_email = email.reverse
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      # Your decryption logic here
      decrypted_email = encrypted_email.reverse
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted_email}"
      decrypted_email
    end
  end

  class ::User
    before_save :encrypt_email_if_present

    def encrypt_email_if_present
      if self.email.present?
        Rails.logger.info "PIIEncryption: Encrypting email for user: #{self.username}"
        self.email = PIIEncryption.encrypt_email(self.email)
      end
    end

    def decrypt_email
      encrypted_email = self.email
      PIIEncryption.decrypt_email(encrypted_email)
    end
  end
end
 
