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
require 'openssl'
require 'base64'

after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  require_dependency 'user_email'

  module ::PIIEncryption
    KEY = Base64.decode64(ENV['EMAIL_ENCRYPTION_KEY'])

    def self.encrypt_email(email)
      return email if email.nil? || email.empty?

      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt
      cipher.key = KEY
      iv = cipher.random_iv
      encrypted_email = cipher.update(email) + cipher.final
      encrypted_data = iv + encrypted_email

      Base64.strict_encode64(encrypted_data)
    rescue => e
      Rails.logger.error "PIIEncryption: Error encrypting email - #{e.message}"
      nil
    end

    def self.decrypt_email(encrypted_email)
      return encrypted_email if encrypted_email.nil? || encrypted_email.empty?

      encrypted_data = Base64.strict_decode64(encrypted_email)
      iv = encrypted_data[0, 16] # Ensure we slice correctly for the 16 bytes IV
      encrypted_message = encrypted_data[16..-1]

      decipher = OpenSSL::Cipher.new('AES-256-CBC')
      decipher.decrypt
      decipher.key = KEY
      decipher.iv = iv

      decipher.update(encrypted_message) + decipher.final
    rescue => e
      Rails.logger.error "PIIEncryption: Error decrypting email - #{e.message}"
      nil
    end
  end

  class ::UserEmail
    before_save :encrypt_email_address

    def email
      @decrypted_email ||= PIIEncryption.decrypt_email(read_attribute(:email))
    end

    def email=(value)
      @decrypted_email = value
      write_attribute(:email, PIIEncryption.encrypt_email(value))
    end

    private

    def encrypt_email_address
      if email_changed? && @decrypted_email.present?
        write_attribute(:email, PIIEncryption.encrypt_email(@decrypted_email))
      end
    end
  end

  # Ensure we do not decrypt the email during validation
  module ::PIIEncryption::UserPatch
    def email
      if new_record?
        # Return the raw email attribute during the signup process
        read_attribute(:email)
      else
        super
      end
    end
  end

  ::User.prepend(::PIIEncryption::UserPatch)
end
