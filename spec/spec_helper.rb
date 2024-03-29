# frozen_string_literal: true

require 'bundler/setup'
require 'airship'
require 'faraday'
require 'active_support'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/securerandom'
require 'active_support/core_ext/time/zones'
require 'active_support/version'
require 'active_support/deprecation' if ActiveSupport::VERSION::MAJOR > 6
require 'active_support/isolated_execution_state' if ActiveSupport::VERSION::MAJOR > 6
require 'webmock/rspec'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
Time.zone = 'UTC'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Guard tries to run only tests with the focus tag, if this would filter out
  # all specs, run all tests.
  config.run_all_when_everything_filtered = true

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
