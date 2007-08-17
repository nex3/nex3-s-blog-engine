class CommentsBelongToPosts < ActiveRecord::Migration
  def self.up
    add_column 'comments', 'post_id', :integer
  end

  def self.down
    remove_column 'comments', 'post_id'
  end
end
