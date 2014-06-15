# reactor.gem

### A Sidekiq-backed pub/sub layer for your Rails app.

Warning: this is under active development!

This gem aims to provide the following tools to augment your ActiveRecord & Sidekiq stack.

 1. Barebones event API through Sidekiq to publish whatever you want
 2. Database-driven API to manage subscribers so that users may rewire whatever you let them (transactional emails, campaigns, etc...)
 3. Static/Code-driven API to subscribe a basic ruby block to an event.
 4. A new communication pattern between your ActiveRecord models that runs asynchronously through Sidekiq.
    a. describe model lifecycle events and callbacks with class-level helper methods/DSL

## Installation

Add this line to your application's Gemfile:

    gem 'reactor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reactor

## Usage

Well, this is evolving, so it's probably best to go read the specs.


### Barebones API

```ruby
Reactor::Event.publish(:event_name, any: 'data', you: 'want')
```

### ActiveModel extensions

#### Publishable

  Describe lifecycle events like so

```ruby
publishes :my_model_created
publishes :state_has_changed, if: -> { state_has_changed? }
```

#### Subscribable

  You can now bind any block to an event in your models like so

```ruby
on_event :any_event do |event|
  event.target.do_something_about_it!
end
```

  Static subscribers like these are automatically placed into Sidekiq and executed in the background

  It's also possible to run a subscriber block in memory like so

```ruby
on_event :any_event, in_memory: true do |event|
  event.target.do_something_about_it_and_make_the_user_wait!
end
```

### Testing

Calling `Reactor.test_mode!` enables test mode.  (You should call this as early as possible, before your subscriber classes
are declared).  In test mode, no subscribers will fire unless they are specifically enabled, which can be accomplished
by calling
```ruby
Reactor.enable_test_mode_subscriber(MyAwesomeSubscriberClass)
```

We also provide
```ruby
Reactor.with_subscriber_enabled(MyClass) do
  # stuff
end
```

for your testing convenience.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Open Source by Hired

[Hired](https://hired.com/?utm_source=opensource&utm_medium=reactor&utm_campaign=readme) wants to make sure every developer in the world has a kick-ass job with an awesome salary and great coworkers. 

Our site allows you to quickly create a profile and then get offers from some of the top companies in the world - with salary and equity disclosed up-front. Average Ruby engineer salaries on Hired are around $120,000 per year, but if you are smart enough to use Reactor you'll probably be able to get more like $150,000 :).


<a href="https://hired.com/?utm_source=opensource&utm_medium=reactor&utm_campaign=readme-banner" target="_blank">
<img src="https://dmrxx81gnj0ct.cloudfront.net/public/hired-banner-light-1-728x90.png" alt="Hired" width="728" height="90" align="center"/>
</a>

We are Ruby developers ourselves, and we use all of our open source projects in production. We always encourge forks, pull requests, and issues. Get in touch with the Hired Engineering team at _opensource@hired.com_.

