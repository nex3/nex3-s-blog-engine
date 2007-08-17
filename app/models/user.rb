require 'digest/sha1'

class User < ActiveRecord::Base
  validates_presence_of :name
  validates_length_of :name, :maximum => 30

  has_many :comments

  attr_accessor :password, :password_confirm

  validate :name_should_be_unique
  before_save :nillify_attrs, :set_password

  def self.login(name, pass)
    user = find_by_name(name)
    if user && user.pass_hash && user.pass_hash == Digest::SHA1.hexdigest(user.salt + pass)
      user
    else
      nil
    end
  end

  def self.admins
    find_all_by_admin true
  end

  def self.anon
    User.new :name => 'Anonymous'
  end

  def self.all_sorted_by_count
    find_by_sql <<END
SELECT users.*, COUNT(comments.id) AS ccount
FROM users
LEFT JOIN comments
ON comments.user_id = users.id
GROUP BY users.id
ORDER BY ccount DESC
END
  end

  def comment_count
    @comment_count ||= if self.respond_to?('ccount')
                         self.ccount.to_i
                       else
                         self.class.count_by_sql ['SELECT COUNT(*) FROM comments c WHERE c.user_id = ?', id]
                       end
  end

  def href
    link =~ /^http:\/\// ? link : "http://#{link}"
  end

  private

  def name_should_be_unique
    if self.class.admins.any? { |u| u != self && u.name == self.name }
      errors.add(:name, 'is already in use. Please choose another.')
    end
  end

  def nillify_attrs
    self.password = nil if password && password.empty?
    self.salt = nil if salt && salt.empty?
    self.pass_hash = nil if pass_hash && pass_hash.empty?
    self.link = nil if link && link.empty?
    self.email = nil if email && email.empty?
  end
  
  def set_password
    if password
      if password == password_confirm
        self.salt = ('\1'..'\255').sort{rand}[0..16].join
        self.pass_hash = Digest::SHA1.hexdigest(salt + password)
      else
        errors.add(:password, ' and confirmation must match.')
        return false
      end
    end
  end
end
