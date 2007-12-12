class CreateTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name, :null => false
    end

    create_table :posts_tags, :id => false do |t|
      t.integer :post_id
      t.integer :tag_id
    end

    add_index :posts_tags, :post_id
    add_index :posts_tags, :tag_id
  end

  def self.down
    drop_table :tags
    drop_table :posts
  end
end
