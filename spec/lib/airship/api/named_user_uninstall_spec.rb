# frozen_string_literal: true


RSpec.describe Airship::Api::NamedUserUninstall do
  subject { described_class.call(operation_params) }

  let(:operation_params) do
    {
      app_key:       app_key,
      master_secret: master_secret,
      named_user_id: named_user_id
    }
  end

  let(:app_key) { 'airship_app_andromeda' }
  let(:master_secret) { '***master_secret***' }
  let(:basic_auth_token) { Base64.encode64("#{app_key}:#{master_secret}").strip }

  let(:named_user_id) { 'han.solo' }

  let(:expected_endpoint) { 'named_users/uninstall' }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }

  let(:request_body) do
    {
      named_user_id: [named_user_id]
    }.with_indifferent_access
  end

  let(:response_status) { 200 }
  let(:response_body) { '{"ok":true}' }

  before do
    stub_request(:post, expected_full_path)
      .with(
        headers: {
          'Accept'        => 'application/vnd.urbanairship+json; version=3',
          'Authorization' => "Basic #{basic_auth_token}",
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

  it 'tracks the request with Prometheus' do
    expect(PrometheusMetrics).to receive(:observe).with(
      :third_party_requests_total,
      1,
      provider: 'airship',
      action:   expected_endpoint
    )

    subject
  end

  it 'doesn\'t track an error with Prometheus' do
    expect(PrometheusMetrics).not_to receive(:observe).with(
      :third_party_errors_total,
      1,
      hash_including(provider: 'airship')
    )

    subject
  end

  context 'with a failing HTTP response' do
    let(:response_status) { 401 }
    let(:response_body) do
      '{"ok":false,"error":"Unauthorized","error_code":40101}'
    end

    let(:response_status) { 401 }
    let(:response_body) do
      '{"ok":false,"error":"Unauthorized","error_code":40101}'
    end

    it 'is expected not to succeed' do
      expect { subject }.to raise_error Airship::Api::Unauthorized
    end

    it 'tracks the request and the according error with Prometheus' do
      expect(PrometheusMetrics).to receive(:observe).with(
        :third_party_requests_total,
        1,
        provider: 'airship',
        action:   expected_endpoint
      ).ordered

      expect(PrometheusMetrics).to receive(:observe).with(
        :third_party_errors_total,
        1,
        hash_including(
          provider:          'airship',
          unexpected_status: response_status
        )
      ).ordered

      expect { subject }.to raise_error Airship::Api::Unauthorized
    end
  end
end
