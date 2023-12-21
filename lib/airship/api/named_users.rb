# frozen_string_literal: true

module Airship
  module Api
    # see also documentation:
    # - Add Custom Events => https://docs.airship.com/api/ua/#operation/api/named_users/get
    class NamedUsers < Base
      receives :app_key
      receives :token

      receives :page
      receives :page_size

      class << self
        def each(options = {})
          raise ArgumentError, 'argument must be a Hash' unless options.is_a?(Hash)

          page = 0
          page_size = options[:page_size] || 1000

          loop do
            page += 1

            operation_instance = new(options.merge(page:, page_size:))
            result = operation_instance.call
            named_users = Array(result['named_users'])

            named_users.each do |named_user|
              yield named_user
            end

            return if named_users.size < page_size
          end
        end
      end

      protected

      def api_endpoint
        'named_users'
      end

      def request_parameters
        {
          page:      page || 1,
          page_size: page_size || 1000
        }
      end

      def process_request
        process_get_request
      end
    end
  end
end
