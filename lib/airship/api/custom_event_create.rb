# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/custom-events/post
    class CustomEventCreate < Airship::Api::Base
      receives :app_key
      receives :token

      receives :event_name
      receives :occurred_at
      receives :named_user_id
      receives :additional_payload

      protected

      def api_endpoint
        'custom-events'
      end

      def request_body
        assert_additional_payload_has_flat_values!

        [
          {
            # ISO8601 in UTC
            occurred: occurred,
            user:     {
              named_user_id: named_user_id
            },
            body:     {
              # required. lower case.
              name:       event_name.to_s.downcase,
              # optional. "An object containing custom event properties."
              properties: additional_payload
            }
          }
        ].to_json
      end

      def assert_additional_payload_has_flat_values!
        return if additional_payload.values.none? { |v| v.is_a? Hash }

        raise ArgumentError, 'additional_payload must not be nested'
      end

      def occurred
        time = if occurred_at.is_a?(String)
                 Time.parse(occurred_at)
               else
                 occurred_at
               end

        time.utc.iso8601
      end
    end
  end
end
