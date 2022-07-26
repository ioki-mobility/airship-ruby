# frozen_string_literal: true

#require 'rails_helper'

RSpec.describe Airship::Api::CustomEventCreate do
  subject { described_class.call(operation_params) }
  let(:operation_params) do
    {
      app_key:            app_key,
      token:              token,
      event_name:         event_name,
      occurred_at:        occurred_at,
      named_user_id:      named_user_id,
      additional_payload: additional_payload
    }
  end

  let(:app_key) { 'airship_app_andromeda' }
  let(:token) { '***TOKEN***' }

  let(:event_name) { 'eat_pizza' }
  let(:occurred_at) { '2020-03-13T17:30:45Z' }
  let(:named_user_id) { 'han.solo' }
  let(:additional_payload) { { favorite_vehicle: 'Millenium Falcon' } }

  # transformed timestamp in request_body
  let(:occured) { '2020-03-13T17:30:45Z' }

  let(:expected_endpoint) { 'custom-events' }
  let(:expected_full_path) { described_class::AIRSHIP_API_BASE_URL + expected_endpoint }

  let(:request_body) do
    [
      {
        occurred: occured,
        user:     {
          named_user_id: named_user_id
        },
        body:     {
          name:       event_name,
          properties: {
            favorite_vehicle: 'Millenium Falcon'
          }
        }
      }.with_indifferent_access
    ]
  end

  let(:response_status) { 200 }
  let(:response_body) { { 'ok' => true, 'operationId' => '2eac7ca7-ce2f-4242-90b6-56172847a5d8' }.to_json }

  before do
    stub_request(:post, expected_full_path)
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

  context 'when given occurred_at is any DateTime object' do
    let(:occurred_at) { Time.zone.local(2020, 3, 13, 17, 30, 45) }

    it 'is expected to succeed with same request-footprint' do
      expect { subject }.not_to raise_error
    end
  end

  context 'when additional_paylaod is not a flat object' do
    let(:additional_payload) do
      {
        first_level: {
          second_level: 'this cannot be processed by airship'
        }
      }
    end

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error ArgumentError
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