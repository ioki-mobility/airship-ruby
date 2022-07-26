# frozen_string_literal: true

#require 'rails_helper'

RSpec.describe Airship::Api::EmailChannelLookup do
  subject { described_class.call(operation_params) }
  let(:operation_params) do
    {
      app_key: app_key,
      token:   token,
      email:   email
    }
  end

  let(:app_key) { 'airship_app_andromeda' }
  let(:token) { '***TOKEN***' }
  let(:email) { 'han.solo@rebellion.sw' }

  let(:expected_endpoint) { 'channels/email/han.solo%40rebellion.sw' }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }

  let(:response_status) { 200 }
  let(:response_body) do
    <<-JSON
    {
        "ok": true,
        "channel": {
            "channel_id": "0e8a2bf4-c735-4833-a16e-46093157a9d4",
            "device_type": "email",
            "installed": true,
            "background": false,
            "named_user_id": "8096b84d-8f83-4acf-a5a7-a988e8f6fe09",
            "tags": [],
            "tag_groups": {
                "ua_channel_type": ["email"],
                "ua_background_enabled": ["false"],
                "timezone": ["Africa/Lagos"],
                "named_user_id": ["8096b84d-8f83-4acf-a5a7-a988e8f6fe09"],
                "ua_locale_language": ["de"],
                "ua_opt_in": ["true"]
            },
            "device_attributes": {
                "ua_nu_language": "de",
                "ua_local_tz": "Africa/Lagos",
                "ua_language": "de",
                "ua_nu_local_tz": "Europe/Rome",
                "ua_nu_country": "DE"
            },
            "attributes": {},
            "created": "2020-11-10T18:04:28",
            "address": null,
            "opt_in": true,
            "commercial_opted_in": "2020-11-10T19:49:24",
            "commercial_opted_out": "2020-11-10T20:06:10",
            "transactional_opted_out": "2020-11-10T20:06:10",
            "last_registration": "2020-11-10T20:06:10"
        }
    }
    JSON
  end

  before do
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
