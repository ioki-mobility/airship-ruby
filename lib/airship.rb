# frozen_string_literal: true

require_relative 'airship/version'

require 'active_support/configurable'

module Airship
  include ActiveSupport::Configurable
  Airship.config.request_tracker ||= Proc.new {|api_endpoint| nil }
  Airship.config.error_tracker   ||= Proc.new {|api_endpoint, response_code| nil }

  require_relative 'airship/api/base'
  require_relative 'airship/api/channel_uninstall'
  require_relative 'airship/api/custom_event_create'
  require_relative 'airship/api/email_channel_create'
  require_relative 'airship/api/email_channel_lookup'
  require_relative 'airship/api/email_channel_uninstall'
  require_relative 'airship/api/email_channel_update'
  require_relative 'airship/api/named_user_associate_email'
  require_relative 'airship/api/named_user_lookup'
  require_relative 'airship/api/named_user_tags_update'
  require_relative 'airship/api/named_user_uninstall'
end
