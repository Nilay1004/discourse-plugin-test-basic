# frozen_string_literal: true

# name: discourse-plugin-test-basic
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

require 'net/http'
require 'uri'
require 'json'

after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  require_dependency 'user_email'

  module ::PIIEncryption
    def self.encrypt_email(email)
      return email if email.nil? || email.empty?

      uri = URI.parse("http://35.174.88.137:8080/encrypt")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = { data: email, pii_type: "email" }.to_json
      Rails.logger.info "PIIEncryption: Sending encryption request for email: #{email}"
      response = http.request(request)

      encrypted_email = JSON.parse(response.body)["encrypted_data"]
      Rails.logger.info "PIIEncryption: Encrypted email: #{encrypted_email}"
      encrypted_email
    rescue StandardError => e
      Rails.logger.error "Error encrypting email: #{e.message}"
      email
    end

    def self.decrypt_email(encrypted_email)
      return encrypted_email if encrypted_email.nil? || encrypted_email.empty?

      uri = URI.parse("http://35.174.88.137:8080/decrypt")
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = { data: encrypted_email, pii_data: "email" }.to_json
      Rails.logger.info "PIIEncryption: Sending decryption request for encrypted email: #{encrypted_email}"
      response = http.request(request)

      decrypted_email = JSON.parse(response.body)["decrypted_data"]
      Rails.logger.info "PIIEncryption: Decrypted email: #{decrypted_email}"
      decrypted_email
    rescue StandardError => e
      Rails.logger.error "Error decrypting email: #{e.message}"
      encrypted_email
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
