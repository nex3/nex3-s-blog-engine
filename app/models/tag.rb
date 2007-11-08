class Tag < ActiveRecord::Base
  validates_length_of :name, :minimum => 1
  has_and_belongs_to_many :posts

  def self.all_with_postcount
    tags = self.find_by_sql <<-END
      SELECT tags.*, COUNT(posts_tags.post_id) AS post_count FROM tags
      LEFT OUTER JOIN posts_tags ON posts_tags.tag_id = tags.id
      GROUP BY posts_tags.tag_id
      ORDER BY post_count DESC
    END
    tags.select { |tag| tag.post_count >= Post.count / 10 }
  end

  # Warning: returns nil if not retrieved with Tag.all_with_postcount
  def post_count
    count = read_attribute('post_count')
    count && count.to_i
  end
end
