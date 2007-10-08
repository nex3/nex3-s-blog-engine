require 'redcloth'

class Comment < ActiveRecord::Base
  validates_presence_of :content
  validates_presence_of :post_id
  belongs_to :post
  belongs_to :user

  def render
    rc = RedCloth.new(content || '')
    unless self.user && self.user.admin?
      rc.filter_html = true
      rc.filter_styles = true
    end

    rc.to_html.gsub(/<p>\s*<sup>[0-9]+<\/sup>/) do |s|
      num = s.scan(/[0-9]+/)[0].to_i
      "<p id=\"fn#{num}\"><sup>#{num}</sup>"
    end.gsub(/fn[0-9]+/) do |s|
      "comment-#{id || 'new'}-fn#{s[2..-1]}"
    end.gsub(/id="[^"]*fn[^"]*"/) {|s| s + ' class="footnote"'}
  end

  def uid
    "nex-3.com,#{created_at.strftime('%Y-%m-%d')}:comments/#{id}"
  end

  def user_with_anon
    user_without_anon || User.anon
  end
  alias_method_chain :user, :anon

  def spam?
    @spam = AkismetInstance.commentCheck(*akismet_info) if @spam.nil?
    @spam
  end

  def spam!
    @spam = true
    AkismetInstance.submitSpam(*akismet_info)
  end

  def ham!
    @spam = false
    AkismetInstance.submitHam(*akismet_info)
  end

  private

  def akismet_info
    [user.ip, user.agent, user.referrer, '', 'comment', user.name, user.email, user.link, content, {}]
  end

  def validate
    if user_without_anon && !user.save
      user.errors.each { |name, message| errors.add(name, message) }
    end
  end

  def validate_on_create
    if spam?
      errors.add("content", "determined to be spam. If it's actually not, feel free to email me about it and I'll put it up as soon as I can.")
    end
  end
end
