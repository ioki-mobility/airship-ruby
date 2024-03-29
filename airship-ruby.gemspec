# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'airship/version'

Gem::Specification.new do |spec|
  spec.name          = 'airship-ruby'
  spec.version       = Airship::VERSION
  spec.authors       = ['Daniel Loy']
  spec.email         = ['daniel.loy@ioki.com']

  spec.summary       = 'Simple helper-library to integrate Airship web API'
  spec.description   = 'Simple helper-library to integrate Airship web API'
  spec.homepage      = 'https://github.com/ioki-mobility/airship-ruby'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.7.5'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/ioki-mobility/airship-ruby'
    spec.metadata['changelog_uri'] = 'https://github.com/ioki-mobility/airship-ruby/blob/main/CHANGELOG.md'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 6.1', '< 8.0'
  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'rake', '~> 13.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
