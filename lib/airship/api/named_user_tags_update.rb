# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Named Users Uninstall => https://docs.airship.com/api/ua/#operation/api/named_users/uninstall/post
    class NamedUserTagsUpdate < Base
      TAG_GROUP_NAMESPACE = :ioki

      receives :app_key
      receives :token

      receives :named_user_id
      receives :add_tags
      receives :remove_tags

      protected

      def api_endpoint
        'named_users/tags'
      end

      def request_body
        payload = {
          audience: {
            named_user_id: [named_user_id]
          }
        }

        payload.merge!(add: { TAG_GROUP_NAMESPACE => Array(add_tags) }) if add_tags.present?
        payload.merge!(remove: { TAG_GROUP_NAMESPACE => Array(remove_tags) }) if remove_tags.present?

        payload.to_json
      end
    end
  end
end
