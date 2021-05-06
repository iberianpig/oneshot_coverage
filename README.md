# OneshotCoverage

This gem may not be very useful when you want to use [Coverage onetshot mode](https://bugs.ruby-lang.org/issues/15022),
however, It could be good example to study how to implement by yourself.

This gem provides simple tools to use oneshot mode easier. It gives you:

- Rack middleware for logging
- Pluggable logger interface

Please notice that it records code executions under the target path(usually, project base path).
If you have bundle gem path under target path, It will be ignored automatically.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'oneshot_coverage'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oneshot_coverage

## Usage

### Configuration

```ruby
OneshotCoverage.configure(
  target_path: '/base/project/path',
  logger: OneshotCoverage::Logger::NullLogger.new,
  emit_term: nil, # emit per `emit_term` seconds. It tries to emit per request when `nil`.
)
OneshotCoverage.start
```

As default, OneshotCoverage supports 2 logger.

- OneshotCoverage::Logger::NullLogger (default)
- OneshotCoverage::Logger::StdoutLogger
- OneshotCoverage::Logger::FileLogger

Only required interface is `#post` instance method, so you could implement
by yourself easily.

```ruby
class FileLogger
  def initialize(log_path)
    @log_path = log_path
  end

  # new_logs: Struct.new(:path, :md5_hash, :lines)
  def post(new_logs)
    current_coverage = fetch

    new_logs.each do |new_log|
      key = "#{new_log.path}-#{new_log.md5_hash}"

      logged_lines = current_coverage.fetch(key, [])
      current_coverage[key] = logged_lines | new_log.lines
    end
    save(current_coverage)
  end

  private

  def fetch
    JSON.load(File.read(@log_path))
  rescue Errno::ENOENT
    {}
  end

  def save(data)
    File.write(@log_path, JSON.dump(data))
  end
end
```

### Emit logs

#### With rack application

Please use `OneshotCoverage::Middleware`. This will emit logs per each request.

If you using Rails, middleware will be inserted automatically.

#### With job/batch application

If your job or batch are exit as soon as it finished(i.e. execute via rails runner),
then you don't need to do anything. `OneshotCoverage.start` will set trap
to emit via `at_exit`.
On the other hand, it's not, then you need to emit it manually
at proper timing(i.e. when batch finished)

##### With Sidekiq middleware(optional)
You can use Sidekiq server middleware to emit logs after each job's `perform` method.
Add following configuration to `config/initializers/sidekiq.rb`.

```ruby
require `oneshot_coverage/sidekiq_middleware.rb` 

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add OneshotCoverage::SidekiqMiddleware::Server
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OneshotCoverage project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/riseshia/oneshot_coverage/blob/master/CODE_OF_CONDUCT.md).
