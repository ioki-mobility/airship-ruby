# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/channels/uninstall/post
    class ChannelUninstall < Base
      receives :app_key
      receives :token

      receives :channel_id
      receives :device_type

      SUPPORTED_DEVICE_TYPES = %w[ios android email].freeze

      protected

      def api_endpoint
        'channels/uninstall'
      end

      def request_body
        assert_supported_device_type!

        {
          channel_id:  channel_id,
          device_type: device_type
        }.to_json
      end

      def assert_supported_device_type!
        return if SUPPORTED_DEVICE_TYPES.include?(device_type)

        raise ArgumentError, "Device-type '#{device_type}' is not suppport by Airship"
      end
    end
  end
end
