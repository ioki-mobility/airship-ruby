# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Register Email Channel => https://docs.airship.com/api/ua/#operation/api/channels/email/post
    class EmailChannelCreate < Base
      receives :app_key
      receives :token

      receives :email
      receives :commercial_opted_in
      receives :transactional_opted_in
      receives :timezone
      receives :locale_language

      protected

      def api_endpoint
        'channels/email'
      end

      def request_body
        {
          channel: {
            type:                   'email',
            commercial_opted_in:    commercial_opted_in&.to_s(:iso8601),
            transactional_opted_in: transactional_opted_in&.to_s(:iso8601),
            address:                email,
            timezone:               timezone,
            locale_language:        locale_language
          }
        }.to_json
      end
    end
  end
end
