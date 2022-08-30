# frozen_string_literal: true

RSpec.describe Airship::Api::Base do
  subject { described_class.call(operation_params) }

  let(:operation_params) do
    {
      app_key: app_key
    }
  end
  let(:app_key) { 'airship_app_andromeda' }

  let(:request_body) { { dummy_request: 'DUMMY REQUEST' }.to_json }
  let(:response_body) { { dummy_response: 'DUMMY RESPONSE' }.to_json }
  let(:response_status) { 200 }

  let(:expected_endpoint) { 'dummy' }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }

  let(:request_tracker) do
    proc do |api_endpoint|
      api_endpoint
    end
  end

  let(:error_tracker) do
    proc do |api_endpoint, response_code|
      [api_endpoint, response_code]
    end
  end

  before do
    allow(Airship.config).to receive(:request_tracker).and_return(request_tracker)
    allow(Airship.config).to receive(:error_tracker).and_return(error_tracker)

    stub_request(:post, expected_full_path)
      .with(
        body:    request_body,
        headers: {
          'Accept'        => 'application/vnd.urbanairship+json; version=3',
          'Authorization' => '',
          'Content-Type'  => 'application/json',
          'X-Ua-Appkey'   => app_key
        }
      )
      .to_return(status: response_status, body: response_body)
  end

  context 'as instantiated class with implementation' do
    dummy_class(:airship_api_class, described_class) do
      def api_endpoint
        'dummy'
      end

      def request_body
        { dummy_request: 'DUMMY REQUEST' }.to_json
      end
    end

    subject { airship_api_class.call(operation_params) }

    context 'with a successful HTTP response' do
      let(:response_status) { 200 }

      it 'is expected to succeed' do
        expect { subject }.not_to raise_error
      end

      it 'returns the parsed json of the response-body' do
        expect(subject).to eq JSON.parse(response_body)
      end

      it 'tracks the request with configured logger' do
        expect(request_tracker).to receive(:call).with(expected_endpoint)

        subject
      end

      it 'doesn\'t track an error with configured error-tracker' do
        expect(error_tracker).not_to receive(:call)
        subject
      end
    end

    context 'with a failing HTTP response' do
      let(:response_status) { 999 }

      it 'is expected not to succeed' do
        expect { subject }.to raise_error Airship::Api::UnexpectedResponseCode
      end

      it 'tracks the request and the according error with configured trackers' do
        expect(request_tracker).to receive(:call).with(expected_endpoint)
        expect(error_tracker).to receive(:call).with(expected_endpoint, response_status)

        expect { subject }.to raise_error Airship::Api::UnexpectedResponseCode
      end

      context 'when request failed with http-status 401' do
        let(:response_status) { 401 }
        let(:response_body) do
          '{"ok":false,"error":"Unauthorized","error_code":40101}'
        end

        it 'is expected to raise Airship::Api::Unauthorized' do
          expect { subject }.to raise_error Airship::Api::Unauthorized
        end
      end

      context 'when request failed with http-status 403' do
        let(:response_status) { 403 }

        it 'is expected to raise Airship::Api::Forbidden' do
          expect { subject }.to raise_error Airship::Api::Forbidden
        end
      end

      context 'when request failed with http-status 400' do
        let(:response_status) { 400 }
        let(:response_body) do
          '{"ok":false,"error":"SomeRandomError","error_code":40001}'
        end

        it 'is expected to raise Airship::Api::Unauthorized' do
          expect { subject }.to raise_error Airship::Api::UnexpectedResponseCode
        end

        context 'when response-body contains invalid json' do
          let(:response_body) do
            'false}'
          end

          it 'won\'t change the according error-type' do
            expect { subject }.to raise_error Airship::Api::UnexpectedResponseCode
          end
        end

        context 'when error description is about an unfound channel-id' do
          let(:response_status) { 400 }
          let(:response_body) do
            '{"ok":false,"error":"Channel ID [[c7625a59-e576-49da-a68b-1c0ae62de112]] does not exist.",' \
              '"error_code":40001}'
          end

          it 'is expected not to succeed with Airship::Api::ChannelNotFound' do
            expect { subject }.to raise_error Airship::Api::ChannelNotFound
          end
        end

        context 'when error description is about an unknown email' do
          let(:response_status) { 400 }
          let(:response_body) do
            '{"ok":false,"error":"Could not parse request body.","error_code":40022,' \
              '"details":{"error":"Channel id does not exist for email address ' \
              'airship-dummy.6b9a0f99-eea7-4ff2-b26a-815551b9b8b1@example.com"}}'
          end

          it 'is expected not to succeed with Airship::Api::ChannelNotFound' do
            expect { subject }.to raise_error Airship::Api::ChannelNotFound
          end
        end
      end
    end
  end
end
