# frozen_string_literal: true

# name: discourse-plugin-name
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name-darshan"
end

require_relative "lib/my_plugin_module/engine"

after_initialize do
  require_dependency 'user'

  module ::PIIEncryption
    def self.encrypt_email(email)
      # Reverse the email string
      encrypted_email = email.reverse
      encrypted_email
    end
  end

  class ::User
    after_create :encrypt_email_address

    def encrypt_email_address
      self.email = PIIEncryption.encrypt_email(self.email)
      self.save
    end
  end
end
