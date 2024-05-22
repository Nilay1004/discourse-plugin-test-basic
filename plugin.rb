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
      encrypted_email = email.reverse # Simple encryption by reversing the string
      encrypted_email
    end

    def self.decrypt_email(encrypted_email)
      return encrypted_email if encrypted_email.nil? || encrypted_email.empty?
      decrypted_email = encrypted_email.reverse
      decrypted_email
    end
  end

  class ::UserEmail
    before_save :encrypt_email_address

    def email
      decrypted_email = PIIEncryption.decrypt_email(read_attribute(:email))
      decrypted_email
    end

    def email=(value)
      encrypted_email = PIIEncryption.encrypt_email(value)
      write_attribute(:email, encrypted_email)
    end

    private

    def encrypt_email_address
      if email_changed?
        encrypted_email = PIIEncryption.encrypt_email(self[:email])
        write_attribute(:email, encrypted_email)
      end
    end
  end

  module ::PIIEncryption::UserPatch
    def email
      decrypted_email = PIIEncryption.decrypt_email(super)
      decrypted_email
    end

    def self.find_by_email(email)
      encrypted_email = ::PIIEncryption.encrypt_email(email)
      find_by(email: encrypted_email)
    end
  end

  ::User.singleton_class.prepend(::PIIEncryption::UserPatch)

  module ::Auth::PIIEncryptionCurrentUserProviderPatch
    def find_user_from_email(email)
      encrypted_email = ::PIIEncryption.encrypt_email(email)
      user_email = UserEmail.find_by(email: encrypted_email)
      user = user_email&.user
      user
    end
  end

  ::Auth::DefaultCurrentUserProvider.prepend(::Auth::PIIEncryptionCurrentUserProviderPatch)
end
