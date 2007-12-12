class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :name, :null => false
      t.boolean :admin, :default => false
      t.string  :email
      t.string  :link
      t.string  :pass_hash
      t.string  :salt
      t.string  :ip
      t.string  :agent
      t.string  :referrer
    end
  end

  def self.down
    drop_table :users
  end
end
