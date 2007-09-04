class AddUserInfo < ActiveRecord::Migration
  def self.up
    add_column 'users', 'ip', :string
    add_column 'users', 'agent', :string
    add_column 'users', 'referrer', :string
  end

  def self.down
    remove_column 'users', 'ip'
    remove_column 'users', 'agent'
    remove_column 'users', 'referrer'
  end
end
