# Raven-Ruby

[![Build Status](https://secure.travis-ci.org/getsentry/raven-ruby.png?branch=master)](http://travis-ci.org/getsentry/raven-ruby)

A client and integration layer for the [Sentry](https://github.com/getsentry/sentry) error reporting API.

This library is still forming, so if you are looking to just use it, please check back in a few weeks.

## Installation

Add the following to your `Gemfile`:

```ruby
gem "sentry-raven", :git => "https://github.com/getsentry/raven-ruby.git"
```

Or install manually
```bash
$ gem install sentry-raven
```

## Usage

### Rails 3

Add a `config/initializers/raven.rb` containing:

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
end
```

### Rails 2

No support for Rails 2 yet.

### Rack

Basic RackUp file.

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
end

use Raven::Rack
```

### Sinatra

```ruby
require 'sinatra'
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
end

use Raven::Rack

get '/' do
  1 / 0
end
```

### Other Ruby

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'

  # manually configure environment if ENV['RACK_ENV'] is not defined
  config.current_environment = 'production'
end
```


## Capturing Events

Many implementations will automatically capture uncaught exceptions (such as Rails, Sidekiq or by using
the Rack middleware). Sometimes you may want to catch those exceptions, but still report on them.

Several helps are available to assist with this.

### Use the `Raven::Rails::ControllerMethods` module to mixin easy methods

Include the module in your rails application_controller.rb. For a rails app, these would be the most effective way to log an error that you have rescued as it captures the `request.env` data along with any `extra_request_vars` you may have set. For Rails apps, consider using this approach.

```ruby
require 'raven/rails/controller_methods'

class ApplicationController < ActionController::Base
  include Raven::Rails::ControllerMethods
end
```

Then from any controller you can simply call `capture_message` or `capture_exception` to log any errors that you may have rescued

```ruby
def index
  begin
    e = StandardError.new("Some message")
    raise e
  rescue => error
    capture_exception(error)
  end
end

```

#### Raven::Rails::ControllerMethods signature

```
capture_exception( exception, options={} )
capture_message( message_string, options={} )
```
See Additional Context below for more details on the `options` argument


### Capture Exceptions in a Block

```ruby
Raven.capture do
  # capture any exceptions which happen during execution of this block
  1 / 0
end
```

### Capture an Exception by Value

```ruby
begin
  1 / 0
rescue ZeroDivisionError => exception
  Raven.capture_exception(exception)
end
```

### Additional Context

Additional context can be passed to the capture methods.

```ruby
Raven.capture_message("My event", {
  :logger => 'logger',
  :extra => {
    'my_custom_variable' => 'value'
  },
  :tags => {
    'environment' => 'production',
  }
})
```

The following attributes are available:

* `logger`: the logger name to record this event under
* `level`: a string representing the level of this event (fatal, error, warning, info, debug)
* `server_name`: the hostname of the server
* `tags`: a mapping of tags describing this event
* `extra`: a mapping of arbitrary context

## Testing

```bash
$ bundle install
$ rake spec
```

## Notifications in development mode

By default events will only be sent to Sentry if your application is running in a production environment. This is configured by default if you are running a Rack application (i.e. anytime `ENV['RACK_ENV']` is set).

You can configure Raven to run in non-production environments by configuring the `environments` whitelist:

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
  config.environments = %w[ development production ]
end
```

## Excluding Exceptions

If you never wish to be notified of certain exceptions, specify 'excluded_exceptions' in your config file.

In the example below, the exceptions Rails uses to generate 404 responses will be suppressed.

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
  config.excluded_exceptions = ['ActionController::RoutingError', 'ActiveRecord::RecordNotFound']
end
```

## Sanitizing Data (Processors)

If you need to sanitize or pre-process (before its sent to the server) data, you can do so using the Processors
implementation. By default, a single processor is installed (Raven::Processor::SanitizeData), which will attempt to
sanitize keys that match various patterns (e.g. password) and values that resemble credit card numbers.

To specify your own (or to remove the defaults), simply pass them with your configuration:

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
  config.processors = [Raven::Processor::SanitizeData]
end
```

## Capturing additional request data

If you are using a rack based environment like rails you can add an array of `request.env` variables
to be captured and logged in the Request -> Environment data in the Sentry app. To do so set the 
`extra_request_vars` property in config like so:

```ruby
require 'raven'

Raven.configure do |config|
  config.dsn = 'http://public:secret@example.com/project-id'
  config.extra_request_vars = %w[ action_dispatch.request.parameters rack.session ]
end

```

## Other configuration options

There are several configuration options available see `lib/configuration.rb` for a full list. Below are a few options that you may find useful

| name                  | description |
| ----                  | ----------- |
| `environments`        | Whitelist of environments that will send notifications to Sentry |
| `excluded_exceptions` | Which exception types should never be sent |
| `processors`          | Processors to run on data before sending upstream |
| `timeout`             | Timeout when waiting for the server to return data in seconds |
| `open_timeout`        | Timeout waiting for the connection to open in seconds |
| `ssl_verification`    | Should the SSL certificate for the connection of the server be verified? |
| `http_adapter`        | The [Faraday](https://rubygems.org/gems/faraday) adapter to be used. Will default to Net::HTTP when not set |
| `extra_request_vars`  | Array of attributes to include in the 'request data' sent to Sentry. This adds to the defaults that Raven always sends |

## Command Line Interface

Raven includes a basic CLI for testing your DSN:

```ruby
ruby -Ilib ./bin/raven test <DSN>
```

Resources
---------

* [Bug Tracker](http://github.com/getsentry/raven-ruby/issues>)
* [Code](http://github.com/getsentry/raven-ruby>)
* [Mailing List](https://groups.google.com/group/getsentry>)
* [IRC](irc://irc.freenode.net/sentry>)  (irc.freenode.net, #sentry)
