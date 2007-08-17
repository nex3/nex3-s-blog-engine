require File.dirname(__FILE__) + '/../spec_helper'

describe Comment, "with empty content" do
  fixtures :comments

  it "should have one error on content" do
    comments(:contentless).should have(1).error_on(:content)
  end
end

describe Comment, "with nil content" do
  fixtures :comments

  before :each do
    @comment = comments(:contentless)
    @comment.content = nil
  end

  it "should render an empty string" do
    @comment.render.should be_empty
  end
end

describe Comment, "with no post" do
  fixtures :comments

  it "should have one error on post_id" do
    comments(:postless).should have(1).error_on(:post_id)
  end
end

describe Comment, "with no user" do
  fixtures :comments

  it "should belong to an anonymous user" do
    anon = User.new(:name => "Anonymous")
    User.stubs(:anon).returns(anon)

    comments(:userless).user.should == anon
  end
end

describe Comment, "with a user without a name" do
  fixtures :comments, :users

  it "should have one error on name" do
    comments(:nameless).should have(1).error_on(:name)
  end
end

describe Comment, "with both a valid user and a post" do
  fixtures :comments, :users, :posts

  it "should be valid" do
    comments(:two).should be_valid
  end

  it "should reference the proper user" do
    comments(:two).user.should == users(:bob)
  end

  it "should reference the proper post" do
    comments(:three).post.should == posts(:commented)
  end
end

describe Comment, "with formatted content" do
  fixtures :comments, :users

  before(:each) { @rendered = comments(:redclothed).render }

  it "should format the content" do
    @rendered.should include('<strong>bold</strong>')
  end

  it "should make footnote links unique" do
    @rendered.should include('href="#comment-9-fn1"')
    @rendered.should include('id="comment-9-fn1"')
  end

  it "should give footnote paragraphs a 'footnote' class" do
    @rendered.should =~ /<p[^>]+class="footnote"[^>]*>/
  end
end

describe Comment, "with a non-admin poster" do
  fixtures :comments, :users

  before(:each) { @rendered = comments(:redclothed).render }

  it "should get rid of HTML" do
    @rendered.should_not include('<script>')
  end

  it "should get rid of style attributes" do
    @rendered.should_not include('color: green')
  end

  it "should create footnote anchors" do
    @rendered.should include('<p id')
  end
end

describe Comment, "with a poster who is an admin" do
  fixtures :comments, :users

  before(:each) { @rendered = comments(:adminny).render }

  it "shouldn't get rid of HTML" do
    @rendered.should include('<script>')
  end

  it "shouldm't get rid of style attributes" do
    @rendered.should include('color: green')
  end

  it "should create footnote anchors" do
    @rendered.should include('<p id')
  end
end
