# Conflow

[![Build Status](https://travis-ci.org/fanfilmu/conflow.svg?branch=master)](https://travis-ci.org/fanfilmu/conflow) [![Maintainability](https://api.codeclimate.com/v1/badges/80b66a285ca1803f391a/maintainability)](https://codeclimate.com/github/fanfilmu/conflow/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/80b66a285ca1803f391a/test_coverage)](https://codeclimate.com/github/fanfilmu/conflow/test_coverage)

Conflow allows defining comlicated workflows with dependencies. Inspired by [Gush](https://github.com/chaps-io/gush) (the idea) and [Redis::Objects](https://github.com/nateware/redis-objects) (the implementation) it focuses solely on dependency logic, while leaving queueing jobs and executing them entirely in hands of the programmer.

Please have a look at `Gush` if you already use Rails and ActiveJob - it might suit your needs better.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "conflow"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conflow

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/conflow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Conflow project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/conflow/blob/master/CODE_OF_CONDUCT.md).
