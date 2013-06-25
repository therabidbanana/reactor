require 'active_record'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migrator.up "db/migrate"

ActiveRecord::Migration.create_table :auctions do |t|
  t.string :name
  t.datetime :start_at
  t.datetime :close_at

  t.timestamps
end


ActiveRecord::Migration.create_table :events do |t|
  t.string :type

  t.timestamps
end

ActiveRecord::Migration.create_table :subscribers do |t|
  t.integer :event_id
  t.string :matcher
  t.string :type

  t.timestamps
end

ActiveRecord::Migration.create_table :pets do |t|
  t.integer :awesomeness
  t.string :type


  t.timestamps
end

ActiveRecord::Migration.create_table :arbitrary_models do |t|
  t.integer :awesomeness

  t.timestamps
end
