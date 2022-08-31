# frozen_string_literal: true

RSpec.describe Airship::Api::EmailChannelUpdate do
  subject { described_class.call(operation_params) }

  let(:operation_params) do
    {
      app_key:    app_key,
      token:      token,
      channel_id: channel_id,
      email:      email
    }
  end

  let(:app_key) { 'airship_app_andromeda' }
  let(:token) { '***TOKEN***' }

  let(:channel_id) { 'email-123123-23323' }
  let(:email) { 'han.solo@rebellion.sw' }

  let(:expected_endpoint) { "channels/email/#{channel_id}" }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }

  let(:request_body) do
    {
      channel: {
        type:    'email',
        address: email
      }
    }.with_indifferent_access
  end

  let(:response_status) { 200 }
  let(:response_body) { '{"ok":true,"channel_id":"0079cbcd-58b4-40a7-a296-97eeb14f7bc7"}' }

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

    stub_request(:put, expected_full_path)
      .with(
        headers: {
          'Accept'        => 'application/vnd.urbanairship+json; version=3',
          'Authorization' => "Bearer #{token}",
          'Content-Type'  => 'application/json',
          'X-Ua-Appkey'   => app_key
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
