# frozen_string_literal: true

# name: discourse-plugin-name-nilay
# about: Test
# meta_topic_id: 123
# version: 0.0.1
# authors: Nilay
# url: https://github.com/Nilay1004/discourse-plugin-test-basic
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

require 'openssl'
require 'base64'

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name-darshan"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  require_dependency 'user_email'

  module ::PIIEncryption
    KEY = OpenSSL::Cipher::AES.new(256, :CBC).random_key
    IV = OpenSSL::Cipher::AES.new(256, :CBC).random_iv

    def self.encrypt_email(email)
      return email if email.nil? || email.empty?
      cipher = OpenSSL::Cipher::AES.new(256, :CBC)
      cipher.encrypt
      cipher.key = KEY
      cipher.iv = IV
      encrypted = cipher.update(email) + cipher.final
      encrypted_email = Base64.encode64(encrypted)
      Rails.logger.info "PIIEncryption: Encrypting email: #{email}"
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      return encrypted_email if encrypted_email.nil? || encrypted_email.empty?
      decipher = OpenSSL::Cipher::AES.new(256, :CBC)
      decipher.decrypt
      decipher.key = KEY
      decipher.iv = IV
      decrypted = decipher.update(Base64.decode64(encrypted_email)) + decipher.final
      Rails.logger.info "PIIEncryption: Decrypting email: #{encrypted_email}"
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted}"
      decrypted
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
