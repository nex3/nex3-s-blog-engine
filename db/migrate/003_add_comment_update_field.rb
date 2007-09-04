class AddCommentUpdateField < ActiveRecord::Migration
  def self.up
    add_column :comments, :updated_at, :datetime, :default => Time.now
  end

  def self.down
    remove_column :comments, :updated_at
  end
end
