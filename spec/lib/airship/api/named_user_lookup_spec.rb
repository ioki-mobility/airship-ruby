# frozen_string_literal: true

RSpec.describe Airship::Api::NamedUserLookup do
  subject { described_class.call(operation_params) }

  let(:operation_params) do
    {
      app_key:       app_key,
      token:         token,
      named_user_id: named_user_id
    }
  end

  let(:app_key) { 'airship_app_andromeda' }
  let(:token) { '***TOKEN***' }
  let(:named_user_id) { 'harry.potter' }

  let(:expected_endpoint) { 'named_users' }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint + "?id=#{named_user_id}" }

  let(:response_status) { 200 }
  let(:response_body) do
    <<-JSON
      {
        "ok": true,
        "named_user": {
            "named_user_id": "harry.potter",
            "tags": {
                "prison_of_azkaban": ["locked"]
            },
            "created": "2020-03-30T14:38:49",
            "last_modified": "2020-03-31T09:57:32",
            "channels": [{
                "channel_id": "70c0b58f-942f-4b27-b4e3-13f47a80ab28",
                "device_type": "email",
                "installed": true,
                "opt_in": true,
                "background": false,
                "created": "2020-03-27T07:40:57",
                "last_registration": "2020-03-30T15:12:35",
                "alias": null,
                "tags": [],
                "tag_groups": {
                    "ua_channel_type": ["email"],
                    "prison_of_azkaban": ["locked"],
                    "timezone": ["Europe/Paris"],
                    "named_user_id": ["f4f489d7-bb08-4be6-b7a6-0775d3e7f591"],
                    "ua_locale_language": ["en"],
                    "ua_opt_in": ["true"],
                    "ua_background_enabled": ["false"]
                },
                "commercial_opted_in": "2020-03-30T15:12:35"
            }]
        }
      }
    JSON
  end

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

    stub_request(:get, expected_full_path)
      .with(
        headers: {
          'Accept'        => 'application/vnd.urbanairship+json; version=3',
          'Authorization' => "Bearer #{token}",
          'Content-Type'  => 'application/json',
          'X-Ua-Appkey'   => app_key
        }
      )
      .to_return(status: response_status, body: response_body)
  end

  it 'is expected to succeed' do
    expect { subject }.not_to raise_error
  end

  it 'returns the json response-body' do
    expect(subject).to eq JSON.parse(response_body)
  end

  it 'tracks the request with configured tracker' do
    expect(request_tracker).to receive(:call).with(expected_endpoint)
    subject
  end

  it 'doesn\'t track an error with configured tracker' do
    expect(error_tracker).not_to receive(:call)
    subject
  end

  context 'with a failing HTTP response' do
    let(:response_status) { 401 }
    let(:response_body) do
      '{"ok":false,"error":"Unauthorized","error_code":40101}'
    end

    it 'is expected not to succeed' do
      expect { subject }.to raise_error Airship::Api::Unauthorized
    end

    it 'tracks the request and the according error with configured trackers' do
      expect(request_tracker).to receive(:call).with(expected_endpoint)
      expect(error_tracker).to receive(:call).with(expected_endpoint, response_status)
      expect { subject }.to raise_error Airship::Api::Unauthorized
    end
  end
end
