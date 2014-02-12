# Reactor

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

   Event.publish(:event_name, any: 'data', you: 'want')

### ActiveModel extensions

#### Publishable

  Describe lifecycle events like so

    publishes :my_model_created
    publishes :state_has_changed, if: -> { state_has_changed? }

#### Subscribable

  You can now bind any block to an event in your models like so

    on_event :any_event do |event|
      event.target.do_something_about_it!
    end

  Static subscribers like these are automatically placed into Sidekiq and executed in the background

  It's also possible to run a subscriber block in memory like so

    on_event :any_event, in_memory: true do |event|
      event.target.do_something_about_it_and_make_the_user_wait!
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
