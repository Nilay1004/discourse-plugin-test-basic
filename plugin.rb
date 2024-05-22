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
  require_dependency 'user_email'

  module ::PIIEncryption
    def self.encrypt_email(email)
      return email if email.nil? || email.empty?
      Rails.logger.info "PIIEncryption: Encrypting email: #{email}"
      encrypted_email = email.reverse # Simple encryption by reversing the string
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      return encrypted_email if encrypted_email.nil? || encrypted_email.empty?
      Rails.logger.info "PIIEncryption: Decrypting email: #{encrypted_email}"
      decrypted_email = encrypted_email.reverse
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted_email}"
      decrypted_email
    end
  end

  class ::UserEmail
    before_save :encrypt_email_address

    def email
      if new_record?
        # Do not decrypt if the record is new and has not been saved yet
        read_attribute(:email)
      else
        @decrypted_email ||= PIIEncryption.decrypt_email(read_attribute(:email))
      end
    end

    def email=(value)
      # Store the encrypted email in the database
      write_attribute(:email, PIIEncryption.encrypt_email(value))
      @decrypted_email = value
    end

    private

    def encrypt_email_address
      self.email = PIIEncryption.encrypt_email(read_attribute(:email))
    end
  end
end