# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/channels/email/uninstall/post
    class EmailChannelUninstall < Base
      receives :app_key
      receives :token

      receives :email

      protected

      def api_endpoint
        'channels/email/uninstall'
      end

      def request_body
        {
          email_address: email
        }.to_json
      end
    end
  end
end
