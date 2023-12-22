# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/named_users/get
    class NamedUsers < Base
      receives :app_key
      receives :token

      receives :additional_query_params

      class << self
        def each(options = {})
          raise ArgumentError, 'argument must be a Hash' unless options.is_a?(Hash)

          additional_query_params = {}

          loop do
            operation_instance = new(options.merge(additional_query_params: additional_query_params))
            result = operation_instance.call
            named_users = Array(result['named_users'])

            named_users.each do |named_user|
              yield named_user
            end

            break if (named_users.size == 0)
            break if result['next_page'].nil? || result['next_page'] == ''

            uri = URI(result['next_page'])

            additional_query_params = URI::decode_www_form(uri.query).to_h
          end
        end
      end

      protected

      def api_endpoint
        'named_users'
      end

      def request_parameters
        {}.merge(additional_query_params || {})
      end

      def process_request
        process_get_request
      end
    end
  end
end
