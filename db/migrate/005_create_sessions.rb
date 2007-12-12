class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.string   :session_id
      t.text     :data
      t.datetime :updated_at
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
  end

  def self.down
    drop_table :sessions
  end
end
