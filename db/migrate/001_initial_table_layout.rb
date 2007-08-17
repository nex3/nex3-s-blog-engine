class InitialTableLayout < ActiveRecord::Migration
  def self.up
    create_table 'posts' do |t|
      t.column 'title', :string, :null => false
      t.column 'content', :text, :null => false
      t.column 'created_at', :datetime
      t.column 'updated_at', :datetime
    end

    create_table 'users' do |t|
      t.column 'name', :string, :null => false
      t.column 'admin', :boolean, :default => false
      t.column 'email', :string
      t.column 'link', :string
      t.column 'pass_hash', :string
      t.column 'salt', :string
    end

    create_table 'comments' do |t|
      t.column 'user_id', :integer
      t.column 'content', :text, :null => false
      t.column 'created_at', :datetime
    end
  end

  def self.down
    ['posts', 'users', 'comments'].each { |t| drop_table(t) }
  end
end
