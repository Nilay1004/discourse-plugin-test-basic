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

after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  require_dependency 'user_email'

  module PIIEncryption
    def self.decrypt_email(encrypted_email)
      return nil if encrypted_email.nil? || encrypted_email.empty?

      decoded_data = Base64.decode64(encrypted_email)
      iv = decoded_data[0..15]  # AES block size for IV is 16 bytes
      encrypted = decoded_data[16..-1]

      if iv.nil?
        Rails.logger.error "PIIEncryption: IV is nil"
        return nil
      end

      if iv.length != 16
        Rails.logger.error "PIIEncryption: IV length is not 16 bytes"
        return nil
      end

      Rails.logger.info "PIIEncryption: Decrypting email: #{encrypted_email}"
      Rails.logger.info "PIIEncryption: IV length: #{iv.length}"
      Rails.logger.info "PIIEncryption: Encrypted part length: #{encrypted.length}"

      decipher = OpenSSL::Cipher::AES.new(256, :CBC)
      decipher.decrypt
      decipher.key = KEY
      decipher.iv = iv
      decrypted = decipher.update(encrypted) + decipher.final
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
  module PIIEncryption::UserPatch
    def email
      if new_record?
        # Return the raw email attribute during the signup process
        read_attribute(:email)
      else
        super
      end
    end
  end

  ::User.prepend(PIIEncryption::UserPatch)
end
