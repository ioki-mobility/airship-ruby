# frozen_string_literal: true

RSpec.describe Airship::Api::NamedUserAttributesUpdate do
  subject { described_class.call(operation_params) }

  let(:operation_params) do
    {
      app_key:                app_key,
      token:                  token,
      named_user_id:          named_user_id,
      attributes_with_values: { first_name: first_name, last_name: last_name },
      updated_at:             updated_at
    }
  end

  let(:app_key) { 'airship_app_andromeda' }
  let(:token) { '***TOKEN***' }
  let(:named_user_id) { 'harry_potter' }
  let(:first_name) { 'Harry' }
  let(:last_name) { 'Potter' }
  let(:updated_at)  { '2023-01-26 10:04:17' }

  let(:expected_endpoint) { "named_users/#{named_user_id}/attributes" }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }

  let(:request_body) do
    {
      attributes: [
        {
          action:    'set',
          key:       'first_name',
          value:     first_name,
          timestamp: updated_at
        },
        {
          action:    'set',
          key:       'last_name',
          value:     last_name,
          timestamp: updated_at
        }
      ]
    }.with_indifferent_access
  end

  let(:response_status) { 200 }
  let(:response_body) { '{"ok":true}' }

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
        headers: {
          'Accept'          => 'application/vnd.urbanairship+json; version=3',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'   => "Bearer #{token}",
          'Content-Type'    => 'application/json',
          'User-Agent'      => 'Ruby',
          'X-Ua-Appkey'     => app_key
        }
      )
      .with { |request| JSON.parse(request.body) == request_body }
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

  context 'with empty "first_name" parameter' do
    let(:first_name) { nil }

    it 'is expected to succeed with adapted request_body' do
      expect { subject }.not_to raise_error
    end
  end

  context 'with empty "last_name" parameter' do
    let(:last_name) { nil }

    it 'is expected to succeed with adapted request_body' do
      expect { subject }.not_to raise_error
    end
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
