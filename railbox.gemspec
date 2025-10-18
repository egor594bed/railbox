Gem::Specification.new do |spec|
  spec.name          = 'railbox'
  spec.version       = '0.1.1'
  spec.authors       = ['Egor Beresnev']
  spec.email         = ['egor594bed@gmail.com']
  spec.summary       = 'Reliable transactional outbox for background tasks and decoupled processing'
  spec.description   = 'A gem for implementing the transactional outbox pattern with support for HTTP requests and custom message pre-processing.'
  spec.homepage      = 'https://github.com/egor594bed/railbox'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.0.0'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'activejob', '>= 7.0'
  spec.add_dependency 'activerecord', '>= 7.0'
  spec.add_dependency 'faraday', '>= 2.0'
  spec.add_dependency 'faraday-httpclient', '~> 2.0'
  spec.add_dependency 'forwardable', '>= 1.3.3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'sqlite3'
end
