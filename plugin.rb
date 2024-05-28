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

after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  require_dependency 'user_email'

  module ::PIIEncryption
    # Method to encrypt the email using OpenSSL and the encryption key from app.yml
    def self.encrypt_email(email)
      return email if email.nil? || email.empty?

      encryption_key = ENV['EMAIL_ENCRYPTION_KEY']
      raise "Encryption key not found in environment variable EMAIL_ENCRYPTION_KEY" if encryption_key.nil?

      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt
      cipher.key = encryption_key
      iv = cipher.random_iv

      encrypted_email = cipher.update(email) + cipher.final
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      { ciphertext: encrypted_email, iv: iv }
    end

    # Method to decrypt the email using OpenSSL and the encryption key from app.yml
    def self.decrypt_email(encrypted_data)
      return encrypted_data if encrypted_data.nil? || encrypted_data.empty?

      encryption_key = ENV['EMAIL_ENCRYPTION_KEY']
      raise "Encryption key not found in environment variable EMAIL_ENCRYPTION_KEY" if encryption_key.nil?

      decipher = OpenSSL::Cipher.new('AES-256-CBC')
      decipher.decrypt
      decipher.key = encryption_key
      decipher.iv = encrypted_data[:iv]

      decrypted_email = decipher.update(encrypted_data[:ciphertext]) + decipher.final
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted_email}"
      decrypted_email
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
      if email_changed?
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
