require 'redcloth'

class Post < ActiveRecord::Base
  validates_presence_of :title, :content
  has_many :comments, :dependent => :destroy, :order => 'created_at'

  def render
    render_string content
  end

  def render_small
    pgraphs = paragraphs[0...3]
    if pgraphs[-1] && pgraphs[-1][0] == ?!
      pgraphs = pgraphs[0...2]
    end
    render_string pgraphs.join("\r\n\r\n")
  end

  def comment_count
    @comment_count ||= self.class.count_by_sql ['SELECT COUNT(*) FROM comments c WHERE c.post_id = ?', id]
  end

  def paragraphs
    @paragraphs ||= content.split(/\r?\n\r?\n/)
  end

  def next
    next_or_prev('>', '')
  end

  def prev
    next_or_prev('<', 'DESC')
  end

  def uid
    "nex3.leeweiz.net,#{created_at.strftime('%Y-%m-%d')}:#{id}"
  end

  def slug
    title.downcase.gsub(/[^a-z0-9_]/, '-').gsub(/--+/, '-').gsub(/-*$/, '')
  end

  def self.oldest
    self.find(:first, :order => 'created_at')
  end

  def self.newest
    self.find(:first, :order => 'created_at DESC')
  end

  def self.after(date)
    self.find(:first, :conditions => ['created_at > ?', date], :order => 'created_at')
  end

  def self.before(date)
    self.find(:first, :conditions => ['created_at < ?', date], :order => 'created_at DESC')
  end

  def self.between(date1, date2)
    Post.find(:all, :conditions => ['created_at >= ? AND created_at < ?', date1, date2],
              :order => 'created_at DESC')
  end

  def self.months_spanned
    @months_spanned ||= begin
                          months = []

                          if newest = Post.newest
                            date = newest.created_at.to_time
                            oldest = Post.oldest.created_at.to_time

                            until date < oldest
                              months << date
                              date = date.last_month
                            end
                          end

                          months
                        end
  end

  private

  def next_or_prev(op, order)
    Post.find(:first, :conditions => ["created_at #{op} ?", created_at], :order => "created_at #{order}")
  end

  def render_string(to_render)
    RedCloth.new(to_render).to_html.gsub(/fn[0-9]+/) do |s|
      "post-#{id || 'new'}-fn#{s[2..-1]}"
    end.gsub(/id="[^"]*fn[^"]*"/) {|s| s + ' class="footnote"'}
  end
end