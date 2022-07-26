# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/channels/email/email_channel_id/put
    class EmailChannelUpdate < Base
      receives :app_key
      receives :token

      receives :channel_id
      receives :email

      protected

      def api_endpoint
        "channels/email/#{channel_id}"
      end

      def process_request
        process_put_request
      end

      def request_body
        {
          channel: {
            type:    'email',
            address: email
          }
        }.to_json
      end
    end
  end
end
