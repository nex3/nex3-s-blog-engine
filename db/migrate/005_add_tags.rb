class AddTags < ActiveRecord::Migration
  def self.up
    create_table 'tags' do |t|
      t.column 'name', :string, :null => false
    end

    create_table 'posts_tags', :id => false do |t|
      t.column 'post_id', :integer
      t.column 'tag_id', :integer
    end
    add_index 'posts_tags', 'post_id'
    add_index 'posts_tags', 'tag_id'
  end

  def self.down
    drop_table 'tags'
    drop_table 'posts_tags'
  end
end
