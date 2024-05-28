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
  PLUGIN_NAME = "discourse-plugin-name-nilay"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  Rails.logger.info "SimpleEncryption: Plugin initialized"
  require_dependency 'user_email'

  module ::SimpleEncryption
    KEY = "my_simple_key"  # This should be of a sufficient length for security

    def self.encrypt(data)
      data.bytes.zip(KEY.bytes.cycle).map { |data_byte, key_byte| data_byte ^ key_byte }.pack('C*')
    end

    def self.decrypt(data)
      data.bytes.zip(KEY.bytes.cycle).map { |data_byte, key_byte| data_byte ^ key_byte }.pack('C*')
    end
  end

  class ::UserEmail
    before_save :encrypt_email_address

    def email
      @decrypted_email ||= SimpleEncryption.decrypt(read_attribute(:email))
    end

    def email=(value)
      @decrypted_email = value
      write_attribute(:email, SimpleEncryption.encrypt(value))
    end

    private

    def encrypt_email_address
      if email_changed?
        write_attribute(:email, SimpleEncryption.encrypt(@decrypted_email))
      end
    end
  end

  # Ensure we do not decrypt the email during validation
  module ::SimpleEncryption::UserPatch
    def email
      if new_record?
        # Return the raw email attribute during the signup process
        read_attribute(:email)
      else
        super
      end
    end
  end

  ::User.prepend(::SimpleEncryption::UserPatch)
end