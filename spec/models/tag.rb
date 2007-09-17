require File.dirname(__FILE__) + '/../spec_helper'

describe Tag, " with a couple posts" do
  fixtures :posts, :posts_tags, :tags

  it "should have the proper two posts" do
    tags(:emacs).posts.find(:all, :order => 'title DESC').should == [posts(:commented), posts(:first)]
  end
end

describe Tag, " without a name" do
  fixtures :tags

  it "should have one error on name" do
    tags(:nameless).should have(1).error_on(:title)
  end
end
