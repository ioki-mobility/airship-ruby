# airship-ruby [![CI Status](https://github.com/ioki-mobility/airship-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/ioki-mobility/airship-ruby/actions/workflows/main.yml)

This library helps to integrate the Airship's web-api.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'airship-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install airship-ruby

## Configuration (optional)

Configure custom tracking-procedures in an initializer file `config/airship.rb`

```ruby
require 'airship'

Airship.config.request_tracker = proc do |api_endpoint|
  MyLoggingService.log(
    "Hey guys, I just made a request to Airship (api_endpoint=#{api_endpoint})!"
  )
end

Airship.config.error_tracker = proc do |_api_endpoint, response_code|
  MyErrorMonitoringService.track_error(
    :airship_request_failed,
    endpoint: api_endpoint,
    response_code: response_code
  )
end
```

## Usage
To load this gem run:
```ruby
require 'airship'
end


To perform any Api call:
```ruby
Airship::Api::NamedUserLookup.call(
  app_key:       'my-airship-app-key',
  token:         '***SECRET_AIRSHIP_TOKEN***',
  named_user_id: 'harry.potter'
)
```

The response of an Api call usually returns an json-string of the response-body:

```json
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
```

Any request that results in an unexpected error (meaning all response https-status-codes except `2**`) will raise an `Airship::Api::Error`. Depending on the exact kind  of error it will raise different subclasses of `Airship::Api::Error`:

* `Airship::Api::Unauthorized` if http-status is `401`
* `Airship::Api::Forbidden` if http-status is `403`
* `Airship::Api::ChannelNotFound` if the error-payload of the response-body includes something like `'Channel ID .*does not exist.*'`
* `Airship::Api::UnexpectedResponseCode` for any other kind of error (like http-stauts `500`)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ioki-mobility/airship-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
