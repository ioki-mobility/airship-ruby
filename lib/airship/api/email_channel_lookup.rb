# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/channels/email/email_channel_id/get
    class EmailChannelLookup < Base
      receives :app_key
      receives :token

      receives :email

      protected

      def api_endpoint
        "channels/email/#{ERB::Util.url_encode(email)}"
      end

      def process_request
        process_get_request
      end
    end
  end
end
