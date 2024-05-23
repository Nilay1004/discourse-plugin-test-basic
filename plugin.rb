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
  require_dependency 'session_controller'

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

  module ::PIIEncryption::AuthPatch
    def find_verified_user_by_email(email, *args)
      encrypted_email = PIIEncryption.encrypt_email(email)
      Rails.logger.info "PIIEncryption: Finding user by encrypted email: #{encrypted_email}"
      user_email = UserEmail.find_by(email: encrypted_email)
      if user_email
        Rails.logger.info "PIIEncryption: User found: #{user_email.user.username}"
        user_email.user
      else
        Rails.logger.info "PIIEncryption: No user found for encrypted email: #{encrypted_email}"
        nil
      end
    end

    def log_on_user(user, *args)
      Rails.logger.info "PIIEncryption: Logging on user: #{user.username}"
      super
    end
  end

  ::Auth::DefaultCurrentUserProvider.prepend(::PIIEncryption::AuthPatch)

  DiscourseEvent.on(:user_logged_in) do |user|
    Rails.logger.info "PIIEncryption: User logged in with email: #{user.email}"
  end

  DiscourseEvent.on(:user_failed_login) do |email|
    Rails.logger.info "PIIEncryption: Failed login attempt with email: #{email}"
  end

  # Patch SessionsController to add logging and handle encrypted email during login
  module ::PIIEncryption::SessionsControllerPatch
    def create
      Rails.logger.info "PIIEncryption: SessionsController#create called"
      email = params[:login]&.downcase
      Rails.logger.info "PIIEncryption: Received login email: #{email}"

      encrypted_email = PIIEncryption.encrypt_email(email)
      Rails.logger.info "PIIEncryption: Encrypted login email: #{encrypted_email}"

      params[:login] = encrypted_email

      super

      Rails.logger.info "PIIEncryption: SessionsController#create completed"
    rescue => e
      Rails.logger.error "PIIEncryption: Error in SessionsController#create - #{e.message}"
      raise e
    end
  end

  ::SessionsController.prepend(::PIIEncryption::SessionsControllerPatch)
end