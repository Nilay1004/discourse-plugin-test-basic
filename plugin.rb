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
      # Log the email before and after encryption
      Rails.logger.info "PIIEncryption: Original email: #{email}"
      encrypted_email = email.reverse
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      return nil if encrypted_email.nil?
      Rails.logger.info "PIIEncryption: Decrypting email: #{encrypted_email}"
      decrypted_email = encrypted_email.reverse
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted_email}"
      decrypted_email
    end
  end

  class ::UserEmail
    before_save :encrypt_email_address
    after_save :email

    def encrypt_email_address
      if self.email.present?
       Rails.logger.info "PIIEncryption: Encrypting email for user: #{self.username}"
       self.email = PIIEncryption.encrypt_email(read_attribute(:email))
       self.save
      end
    end

    def email 
      encrypted_email = read_attribute(:email)
      @email=PIIEncryption.decrypt_email(read_attribute(:email))
    end
  end
end
