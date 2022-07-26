# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/named_users/get
    class NamedUserLookup < Base
      receives :app_key
      receives :token

      receives :named_user_id

      protected

      def api_endpoint
        'named_users'
      end

      def request_parameters
        {
          id: named_user_id
        }
      end

      def process_request
        process_get_request
      end
    end
  end
end
