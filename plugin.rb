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
  require_dependency 'email/sender'

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

    def encrypt_email_address
      Rails.logger.info "PIIEncryption: Encrypting email for user ID: #{self.user_id}"
      self.email = PIIEncryption.encrypt_email(self.email)
    end

    def email
      encrypted_email = read_attribute(:email)
      Rails.logger.info "PIIEncryption: Accessing email for user ID: #{self.user_id}. Encrypted email: #{encrypted_email}"
      decrypted_email = PIIEncryption.decrypt_email(encrypted_email)
      Rails.logger.info "PIIEncryption: Decrypted email for user ID: #{self.user_id}: #{decrypted_email}"
      decrypted_email
    end

    def email=(new_email)
      Rails.logger.info "PIIEncryption: Setting email for user ID: #{self.user_id}. New email: #{new_email}"
      encrypted_email = PIIEncryption.encrypt_email(new_email)
      Rails.logger.info "PIIEncryption: Encrypted email to be saved for user ID: #{self.user_id}: #{encrypted_email}"
      write_attribute(:email, encrypted_email)
    end
  end

  # Patch Email::Sender to use decrypted email
  module EmailSenderPatch
    def send
      Rails.logger.info "PIIEncryption: Preparing to send email. Original recipients: #{@to}"
      message.to = @to.map do |recipient|
        user_email = UserEmail.find_by(email: PIIEncryption.encrypt_email(recipient))
        if user_email
          decrypted_email = user_email.email
          Rails.logger.info "PIIEncryption: Decrypted email for recipient: #{decrypted_email}"
          decrypted_email
        else
          recipient
        end
      end
      Rails.logger.info "PIIEncryption: Final recipients after decryption: #{message.to}"
      super
    end
  end

  ::Email::Sender.prepend EmailSenderPatch
end
