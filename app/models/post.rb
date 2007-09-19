require 'redcloth'

class Post < ActiveRecord::Base
  validates_presence_of :title, :content
  has_many :comments, :dependent => :destroy, :order => 'created_at'
  has_and_belongs_to_many :tags, :order => 'name', :before_remove => :destroy_dangling_tag

  def render
    render_string content
  end

  def render_small
    pgraphs = paragraphs[0...3]

    pgraphs = paragraphs[0..4] if pgraphs.first[0] == ?$
    pgraphs.slice! -1 if pgraphs[-1] && pgraphs[-1][0] == ?!

    render_string pgraphs.join("\r\n\r\n")
  end

  def comment_count
    @comment_count ||=
      if self.comments.loaded?
        self.comments.length
      else
        self.class.count_by_sql ['SELECT COUNT(*) FROM comments c WHERE c.post_id = ?', id]
      end
  end

  def comments_with_users
    @comments ||= comments.find(:all, :include => :user)
  end

  def paragraphs
    @paragraphs ||= content.split(/\r?\n\r?\n/)
  end

  def next
    @next ||= next_or_prev('>', '')
  end

  def prev
    @prev ||= next_or_prev('<', 'DESC')
  end

  def uid
    "http://nex-3.com,#{created_at.strftime('%Y-%m-%d')}:#{id}/"
  end

  def slug
    title.downcase.gsub(/[^a-z0-9_]/, '-').gsub(/--+/, '-').gsub(/-*$/, '')
  end

  def tag_string=(tags)
    tags = tags.split(',').map { |t| t.strip.downcase }
    models = Tag.find(:all, :order => 'name', :conditions => [tags.map { "name = ?" }.join(" OR "), *tags])
    models = models.inject({}) { |memo, model| memo[model.name] = model; memo }

    self.tags.clear
    tags.each { |tag| models[tag] ? self.tags << models[tag] : self.tags.build(:name => tag) }
  end

  def tag_string
    tags.map { |t| t.name.downcase }.join(", ")
  end

  class << self
    def oldest
      @oldest ||= find(:first, :select => 'created_at, id', :order => 'created_at')
    end

    def newest
      @newest ||= find(:first, :select => 'created_at, id', :order => 'created_at DESC')
    end

    def after(date)
      find(:first, :conditions => ['created_at > ?', date], :order => 'created_at')
    end

    def before(date)
      find(:first, :conditions => ['created_at < ?', date], :order => 'created_at DESC')
    end

    def between(date1, date2)
      find(:all, :conditions => ['created_at >= ? AND created_at < ?', date1, date2],
           :order => 'created_at DESC')
    end

    def months_spanned
      @months_spanned ||=
        begin
          months = []

          if newest = Post.newest
            date = newest.created_at.to_time
            oldest = Post.oldest.created_at.to_time

            until date < oldest
              months << date
              date = date.last_month
            end

            months << date if date.month == oldest.month
          end

          months
        end
    end

    def find_with_tags(*args)
      handle_option(:tags, args) do |options, tags|
        options[:select] ||= 'posts.*'
        options[:joins]  ||= ''
        options[:joins]  << <<-END
          INNER JOIN posts_tags AS inner_posts_tags ON posts.id = inner_posts_tags.post_id
          INNER JOIN tags AS inner_tags ON inner_tags.id = inner_posts_tags.tag_id
        END
        add_to_conditions(options, tags.map { 'inner_tags.name = ?' }.join(' OR '), *tags)
      end
    end
    alias_method_chain :find, :tags

    def find_with_query(*args)
      handle_option(:query, args) do |options, query|
        if query.empty?
          add_to_conditions(options, 'false')
        else
          term = "%#{query}%"
          add_to_conditions(options, "posts.content LIKE ? OR posts.title LIKE ?", term, term)
        end
      end
    end
    alias_method_chain :find, :query

    private

    def handle_option(name, args)
      options = extract_options_from_args!(args)
      if option = options.delete(name)
        yield options, option
      end
      send("find_without_#{name}", *(args + [options]))
    end

    def add_to_conditions(options, condition, *args)
      condition = args.empty? ? condition : [condition, *args]
      if options[:conditions].nil?
        options[:conditions] = condition
      else
        options[:conditions] = sanitize_sql(options[:conditions]) + " AND (#{sanitize_sql(condition)})"
      end
    end
  end

  private

  def destroy_dangling_tag(tag)
    tag.destroy if tag.posts.count == 1
  end

  def next_or_prev(op, order)
    Post.find(:first, :conditions => ["created_at #{op} ?", created_at],
              :select => 'title, id, created_at', :order => "created_at #{order}")
  end

  def render_string(to_render)
    RedCloth.new(to_render).to_html.gsub(/fn[0-9]+/) do |s|
      "post-#{id || 'new'}-fn#{s[2..-1]}"
    end.gsub(/id="[^"]*fn[^"]*"/) {|s| s + ' class="footnote"'}
  end
end
