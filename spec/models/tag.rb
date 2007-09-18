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

describe Tag, " without a preloaded post_count" do
  fixtures :tags

  it "should return nil for post_count" do
    tags(:emacs).post_count.should be_nil
  end
end

describe Tag, ".all_with_postcount" do
  fixtures :tags

  it "should return all tags, ordered by post count" do
    Tag.all_with_postcount.should == [tags(:emacs), tags(:awesome), tags(:ugly), tags(:nameless)]
  end

  it "should autoload the post count of the tags" do
    Tag.all_with_postcount.map(&:post_count).should == [2, 1, 1, 0]
  end
end
