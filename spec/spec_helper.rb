require 'rubygems'
require 'bundler/setup'
require 'pry'

require 'support/active_record'
require 'sidekiq'
require 'sidekiq/testing/inline'
require 'reactor'
require 'reactor/testing/matchers'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDISTOGO_URL"] }

  database_url = ENV['DATABASE_URL']
  if database_url
    ENV['DATABASE_URL'] = "#{database_url}?pool=25"
    ActiveRecord::Base.establish_connection
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDISTOGO_URL"] }
end


RSpec.configure do |config|
  # some (optional) config here

  config.treat_symbols_as_metadata_keys_with_true_values = true

  # Runs Sidekiq jobs inline by default unless the RSpec metadata :sidekiq is specified,
  # in which case it will use the real Redis-backed Sidekiq queue
  config.before(:each, :sidekiq) do
    Sidekiq.redis{|r| r.flushall }
    Sidekiq::Client.class_eval do
      singleton_class.class_eval do
        alias_method :raw_push, :raw_push_old
      end
    end
  end


  config.after(:each, :sidekiq) do
    load "sidekiq/testing/inline.rb"
  end

end