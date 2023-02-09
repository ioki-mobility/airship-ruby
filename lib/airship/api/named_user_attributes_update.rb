# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Named Users Update Attributes => https://docs.airship.com/api/ua/#operation-api-named_users-named_user_id-attributes-post
    class NamedUserAttributesUpdate < Base
      TAG_GROUP_NAMESPACE = :ioki

      receives :app_key
      receives :token

      receives :named_user_id
      receives :attributes
      receives :updated_at

      protected

      def api_endpoint
        "named_users/#{named_user_id}/attributes"
      end

      def request_body
        {
          attributes: build_attributes
        }.to_json
      end

      def build_attributes
        attributes_with_values.map do |attribute, value|
          {
            action:    'set',
            key:       attribute,
            value:     value,
            timestamp: updated
          }
        end
      end

      def updated
        time = if updated_at.is_a? String
                 Time.parse(updated_at)
               else
                 updated_at
               end

        time.strftime('%Y-%m-%d %H:%M:%S')
      end
    end
  end
end
