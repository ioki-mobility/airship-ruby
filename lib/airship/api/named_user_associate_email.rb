# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Named Users Association => https://docs.airship.com/api/ua/#operation/api/named_users/associate/post
    class NamedUserAssociateEmail < Base
      receives :app_key
      receives :token

      receives :named_user_id
      receives :email

      protected

      def api_endpoint
        'named_users/associate'
      end

      def request_body
        {
          named_user_id: named_user_id,
          email_address: email
        }.to_json
      end
    end
  end
end
