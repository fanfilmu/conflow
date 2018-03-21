# Conflow

[![Gem Version](https://badge.fury.io/rb/conflow.svg)](https://badge.fury.io/rb/conflow) [![Build Status](https://travis-ci.org/fanfilmu/conflow.svg?branch=master)](https://travis-ci.org/fanfilmu/conflow) [![Maintainability](https://api.codeclimate.com/v1/badges/80b66a285ca1803f391a/maintainability)](https://codeclimate.com/github/fanfilmu/conflow/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/80b66a285ca1803f391a/test_coverage)](https://codeclimate.com/github/fanfilmu/conflow/test_coverage)

Conflow allows defining complicated workflows with dependencies. Inspired by [Gush](https://github.com/chaps-io/gush) (the idea) and [Redis::Objects](https://github.com/nateware/redis-objects) (the implementation) it focuses solely on dependency logic, while leaving queueing jobs and executing them entirely in hands of the programmer.

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

### Configuration

#### Redis connection

To configure Redis connection, set `Conflow.redis` attribute to a `Redis` or `ConnectionPool` instance.

```ruby
Conflow.redis = Redis.new(host: "127.0.0.1", port: 6379)
# or
require "connection_pool"
Conflow.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(host: "127.0.0.1", port: 6379) }
```

#### Redis script caching

By default, gem caches it's scripts in Redis server. To disable this behaviour, set `cache_scripts` to false:

```ruby
Conflow::Redis::Scripts.cache_scripts = false
```

### Defining flows

In order to define a flow, first you need to supply a way to enqueue jobs.

`Conflow` does not make any assumptions about this process - you can enqueue Sidekiq job, send a RabbitMQ event or send an email to a Very Important Person with flow ID and job ID.

```ruby
class ApplicationFlow < Conflow::Flow
  def queue(job)
    Sidekiq::Client.enqueue(FlowWorkerJob, id, job.id)
  end
end
```

`id` (`Conflow::Flow#id`) and `job.id` (`Conflow::Job#id`) is enough to identify job and execute it properly. Make sure that you send both of these values and it will be OK.

You can define actual jobs to be performed using `#configure` method:

```ruby
class MyFlow < ApplicationFlow
  def configure(id:, strict:)
    run UpsertJob, params: { id: id }
    run CheckerJob, params: { id: id }, after: UpsertJob if strict
  end
end
```

To create flow, use `.create` method:

```ruby
MyFlow.create(id: 320, strict: false)
MyFlow.create(id: 15, strict: true)
```

#### Dependencies

You can use `after` option to define dependencies. `after` accepts a `Class`, `Conflow::Job` instance or `Integer` with id of the job - or an array with any combination of these.

```ruby
class MyFlow < ApplicationFlow
  def configure
    first = run FirstJob
    independent = run IndependentJob

    run SecondJob, after: [FirstJob, independent]
    run FinishUp, after: SecondJob
  end
end
```

![Created graph](https://camo.githubusercontent.com/0b1ee59994323900906264ea50fbc9169e4d21dd/68747470733a2f2f63686172742e676f6f676c65617069732e636f6d2f63686172743f63686c3d646967726170682b472b2537422530442530412b2b72616e6b6469722533444c522533422530442530412b2b25323253544152542532322b2d2533452b25323246697273744a6f622532322530442530412b2b25323253544152542532322b2d2533452b253232496e646570656e64656e744a6f622532322530442530412b2b25323246697273744a6f622532322b2d2533452b2532325365636f6e644a6f622532322530442530412b2b253232496e646570656e64656e744a6f622532322b2d2533452b2532325365636f6e644a6f622532322530442530412b2b2532325365636f6e644a6f622532322b2d2533452b25323246696e69736855702532322530442530412b2b25323246696e69736855702532322b2d2533452b253232454e442532322530442530412537442530442530412b266368743d6776)

### Performing jobs

To perform job, use `Conflow::Worker` mixin. It adds `#perform` method, which accepts two arguments: IDs of the flow and the job.

Simple `Conflow::Worker` that is also `Sidekiq::Worker`:

```ruby
class FlowWorkerJob
  include Conflow::Worker
  include Sidekiq::Worker # order is important!

  def perform(flow_id, job_id)
    super do |worker_class, params|
      worker_class.new(params).call
    end
  end
end
```

For previously defined flow, executing this flow would result in:

```ruby
FirstJob.new({}).call
IndependentJob.new({}).call # order of the first two is not defined

SecondJob.new({}).call

FinishUp.new({}).call
```

## Theory

The main idea of the gem is, obviously, a directed graph containing information about dependencies. It is stored in Redis in following fields:

* `conflow:job:<id>:successors` - ([List](https://redis.io/topics/data-types#lists)) containing IDs of jobs which depend on `<id>`
* `conflow:flow:<id>:indegee` - ([Sorted Set](https://redis.io/topics/data-types#sorted-sets)) set of all unqueued jobs with score representing how many dependencies are not yet fulfilled

There are three main actions that can be performed on this graph (Redis-wise):

1. Queue jobs
   Removes all jobs with score 0 from `:indegree` set
2. Complete job
   Decrement scores of all of the job's successors by one
3. Add job
   Add job ID to `:successors` list for all jobs on which it depends and add job itself to `:indegree` set

All of these actions are performed via `eval`/`evalsha` - it lifts problems with synchronization (as scripts are executed as if in transaction) and significantly reduces amount of requests made to Redis.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/conflow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Conflow project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/conflow/blob/master/CODE_OF_CONDUCT.md).
