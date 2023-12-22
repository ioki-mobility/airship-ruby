# frozen_string_literal: true

RSpec.describe Airship::Api::NamedUsers do
  subject { described_class.call(operation_params) }

  let(:operation_params) do
    {
      app_key:   app_key,
      token:     token,
      page:      page,
      page_size: page_size
    }
  end

  let(:app_key)   { 'airship_app_andromeda' }
  let(:token)     { '***TOKEN***' }
  let(:page)      { 3 }
  let(:page_size) { 2 }

  let(:expected_endpoint) { 'named_users' }
  let(:expected_full_path) do
    described_class::AIRSHIP_API_BASE_URL + expected_endpoint
  end

  let(:response_status) { 200 }
  let(:response_body) do
    <<-JSON
      {
        "ok": true,
        "named_users": [
          {
            "named_user_id": "harry.potter",
            "channels": [{
                "channel_id": "70c0b58f-942f-4b27-b4e3-13f47a80ab28",
                "device_type": "email"
            }]
          },
          {
            "named_user_id": "ron.weasley",
            "channels": [{
                "channel_id": "9000b48c-245c-cac7-b2e1-12f47a9abab1f",
                "device_type": "email"
            }]
          }
        ],
        "next_page": "#{described_class::AIRSHIP_API_BASE_URL + expected_endpoint + "?start=wonder.woman"}"
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

  describe '#each_batch' do
    let(:page_size) { 2 }

    let(:expected_full_path_1) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }
    let(:expected_full_path_2) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint + '?start=wonder.woman' }

    let(:response_body_2) do
      <<-JSON
        {
          "named_users": [
            {
              "named_user_id": "wonder.woman",
              "channels": [{
                  "channel_id": "0b5870cf-9f42-24b7-b34e-817a3f48b20a",
                  "device_type": "email"
              }]
            }
          ]
        }
      JSON
    end

    let(:response_body_3) { '{"named_users": []}' }

    before do
      stub_request(:get, expected_full_path_1).to_return(status: response_status, body: response_body)
      stub_request(:get, expected_full_path_2).to_return(status: response_status, body: response_body_2)
    end

    it 'makes multiple requests and yields the single named user records' do
      all_data = []

      described_class.each(page_size: page_size) do |data|
        all_data << data
      end

      expect(all_data.size).to eq(3)
      expect(all_data[0]['named_user_id']).to eq('harry.potter')
      expect(all_data[1]['named_user_id']).to eq('ron.weasley')
      expect(all_data[2]['named_user_id']).to eq('wonder.woman')
    end
  end
end
