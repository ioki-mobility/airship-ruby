# frozen_string_literal: true

module Airship
  module Api
    class Error < StandardError; end

    class Unauthorized < Error; end

    class Forbidden < Error; end

    class UnexpectedResponseCode < Error; end

    class ChannelNotFound < Error; end

    # see also documentation:
    # - Authentication => https://docs.airship.com/api/ua/#security
    class Base
      class << self
        def call(options = {})
          raise ArgumentError, 'argument must be a Hash' unless options.is_a?(Hash)

          operation_instance = new(options)
          operation_instance.call
        end

        def receives(option_name)
          define_method option_name do
            options[option_name]
          end
        end
      end

      attr_reader :options

      def initialize(options)
        @options = options
      end

      receives :app_key

      AIRSHIP_API_BASE_URL = 'https://go.airship.eu/api/'
      CHANNEL_NOT_FOUND_ERROR_REGEX = /Channel ID .*does not exist.*/i.freeze

      def call
        track_prometheus_request
        response = process_request

        unless [200, 201, 202].include?(response.status)
          track_prometheus_error(response.status)
          raise Unauthorized if response.status == 401
          raise Forbidden if response.status == 403
          raise ChannelNotFound, error_message_from_response(response) if channel_not_found_error?(response)

          raise UnexpectedResponseCode, error_message_from_response(response)
        end

        JSON.parse(response.body)
      end

      protected

      def api_endpoint
        raise NotImplementedError, 'Override in descendant classes'
      end

      private

      def connection
        Faraday.new do |faraday|
          faraday.adapter :net_http
        end
      end

      def url
        URI.join(AIRSHIP_API_BASE_URL, api_endpoint)
      end

      def process_request
        process_post_request # default action
      end

      def process_post_request
        connection.post(url) do |request|
          request.headers = request_headers
          request.params = request_parameters
          request.body = request_body
        end
      end

      def process_put_request
        connection.put(url) do |request|
          request.headers = request_headers
          request.params = request_parameters
          request.body = request_body
        end
      end

      def process_get_request
        connection.get(url) do |request|
          request.headers = request_headers
          request.params = request_parameters
        end
      end

      def authorization_query
        if respond_to? :token
          "Bearer #{token}"
        elsif respond_to? :master_secret
          encoded_token = Base64.encode64("#{app_key}:#{master_secret}")
          "Basic #{encoded_token}"
        else
          ''
        end
      end

      def request_headers
        {
          'Content-Type'  => 'application/json',
          'Accept'        => 'application/vnd.urbanairship+json; version=3',
          'X-UA-Appkey'   => app_key,
          'Authorization' => authorization_query
        }
      end

      def request_parameters
        {}
      end

      def request_body
        {}.to_json
      end

      def track_prometheus_request
        PrometheusMetrics.observe(
          :third_party_requests_total,
          1,
          provider: 'airship',
          action:   api_endpoint
        )
      end

      def track_prometheus_error(response_code)
        PrometheusMetrics.observe(
          :third_party_errors_total,
          1,
          provider:          'airship',
          unexpected_status: response_code
        )
      end

      def channel_not_found_error?(response)
        parsed_response = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          return false
        end

        error_reason = parsed_response&.dig('error')
        return true if CHANNEL_NOT_FOUND_ERROR_REGEX.match?(error_reason)

        error_reason = parsed_response&.dig('details', 'error')
        return true if CHANNEL_NOT_FOUND_ERROR_REGEX.match?(error_reason)

        false
      end

      def error_message_from_response(response)
        "#{response.status} >> #{response.body}"
      end
    end
  end
end
