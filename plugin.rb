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
  require_dependency 'auth/default_current_user_provider'
  require_dependency 'user'

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
      @decrypted_email ||= begin
        decrypted = PIIEncryption.decrypt_email(read_attribute(:email))
        Rails.logger.info "PIIEncryption: Decrypted email accessed: #{decrypted}"
        decrypted
      end
    end

    def email=(value)
      @decrypted_email = value
      Rails.logger.info "PIIEncryption: Setting email: #{value}"
      write_attribute(:email, PIIEncryption.encrypt_email(value))
    end

    private

    def encrypt_email_address
      if email_changed?
        Rails.logger.info "PIIEncryption: Email changed, encrypting before save."
        write_attribute(:email, PIIEncryption.encrypt_email(@decrypted_email))
      end
    end
  end

  # Ensure we do not decrypt the email during validation
  module ::PIIEncryption::UserPatch
    def email
      if new_record?
        Rails.logger.info "PIIEncryption: New record, returning raw email attribute."
        read_attribute(:email)
      else
        super
      end
    end
  end

  ::User.prepend(::PIIEncryption::UserPatch)

  # Patch the DefaultCurrentUserProvider to handle login with encrypted email
  module ::PIIEncryption::AuthPatch
    def log_on_user(user, session, cookies)
      Rails.logger.info "PIIEncryption: Logging on user: #{user.email}"
      user_email = UserEmail.find_by(email: PIIEncryption.encrypt_email(user.email))
      if user_email
        Rails.logger.info "PIIEncryption: Found user by encrypted email: #{user_email.email}"
        super(user_email.user, session, cookies)
      else
        Rails.logger.info "PIIEncryption: User not found by encrypted email, logging on with given user."
        super
      end
    end

    def find_verified_user_by_email(email)
      encrypted_email = PIIEncryption.encrypt_email(email)
      Rails.logger.info "PIIEncryption: Finding user by encrypted email: #{encrypted_email}"
      UserEmail.find_by(email: encrypted_email)&.user
    end
  end

  ::Auth::DefaultCurrentUserProvider.prepend(::PIIEncryption::AuthPatch)
end