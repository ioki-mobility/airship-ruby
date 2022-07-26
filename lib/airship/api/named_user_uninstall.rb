# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Named Users Uninstall => https://docs.airship.com/api/ua/#operation/api/named_users/uninstall/post
    class NamedUserUninstall < Base
      receives :app_key
      receives :master_secret

      receives :named_user_id

      protected

      def api_endpoint
        'named_users/uninstall'
      end

      def request_body
        {
          named_user_id: [named_user_id]
        }.to_json
      end
    end
  end
end
