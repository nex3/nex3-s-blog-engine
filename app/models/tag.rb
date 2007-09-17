class Tag < ActiveRecord::Base
  validates_length_of :name, :minimum => 1
  has_and_belongs_to_many :posts
end
