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
  require_dependency 'email_sender'

  module ::PIIEncryption
    def self.encrypt_email(email)
      return nil if email.nil?
      Rails.logger.info "PIIEncryption: Encrypting email: #{email}"
      encrypted_email = email.reverse # Simple reversal for demonstration
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

  class ::User
    before_save :encrypt_email_address, if: :email_changed?

    def encrypt_email_address
      Rails.logger.info "PIIEncryption: Encrypting email for user: #{self.username}"
      self.email = PIIEncryption.encrypt_email(self.email)
    end

    # Override the getter for the email attribute
    def email
      encrypted_email = read_attribute(:email)
      PIIEncryption.decrypt_email(encrypted_email)
    end

    # Ensure the mailer uses the decrypted email
    def email_for_mailing
      email
    end
  end

  # Hook into the email sending process to ensure the decrypted email is used
  module UserEmailPatch
    def self.prepended(base)
      base.singleton_class.prepend ClassMethods
    end

    module ClassMethods
      def send_user_email(type, user, *args)
        user_email = user.email_for_mailing
        Rails.logger.info "PIIEncryption: Sending email to #{user_email}"
        super(type, user, *args)
      end
    end
  end

  ::UserEmail.prepend UserEmailPatch
end
