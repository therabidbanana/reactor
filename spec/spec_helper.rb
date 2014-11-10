require 'rubygems'
require 'bundler/setup'
require 'pry'

require 'support/active_record'
require 'sidekiq'
require 'sidekiq/testing/inline'
require 'sidekiq/api'
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

  # Runs Sidekiq jobs inline by default unless the RSpec metadata :sidekiq is specified,
  # in which case it will use the real Redis-backed Sidekiq queue
  config.before(:each, :sidekiq) do
    Sidekiq.redis{|r| r.flushall }
    Sidekiq::Testing.disable!
  end

  config.after(:each, :sidekiq) do
    Sidekiq::Testing.inline!
  end
end