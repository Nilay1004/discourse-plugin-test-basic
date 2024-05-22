# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
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
  require_dependency 'user_email'

  module ::PIIEncryption
    def self.encrypt_email(email)
      # Encryption logic here
      encrypted_email = email.reverse
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      # Decryption logic here
      decrypted_email = encrypted_email.reverse
      decrypted_email
    end
  end

  class ::UserEmail
    before_save :encrypt_email_field

    def email
      # Override to maintain the encrypted state
      read_attribute(:email)
    end

    def decrypted_email
      # Method to get the decrypted email when necessary
      PIIEncryption.decrypt_email(self.email)
    end

    private

    def encrypt_email_field
      self.email = PIIEncryption.encrypt_email(self.email)
    end
  end
end
