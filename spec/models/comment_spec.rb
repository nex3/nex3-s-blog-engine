require File.dirname(__FILE__) + '/../spec_helper'

describe Comment, "with empty content" do
  fixtures :comments

  it "should have one error on content" do
    comments(:contentless).should have(1).error_on(:content)
  end
end

describe Comment, "with one-word content" do
  fixtures :comments

  it "should have one error on content" do
    comments(:oneword).should have(1).error_on(:content)
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

describe Comment, " with potentially spammy content" do
  fixtures :comments, :users

  before(:each) do
    @akismet_info = ["129.67.12.100",
      "Mozilla/5.0 (X11; U; Linux i686; en-GB; rv:1.8.1.6) Gecko/20070919 Ubuntu/7.10 (gutsy) Firefox/2.0.0.6",
      nil, "", "comment", "Bob", "bob@bob.com", "http://www.google.com", "I... love... comments!", {}]
    @comment = comments(:two)
  end

  it "should check with Akismet when spam? is asked" do
    Nex3::Akismet.expects(:commentCheck).with(*@akismet_info).returns(true)
    @comment.should be_spam
  end

  it "should cache a positive spam? result" do
    Nex3::Akismet.expects(:commentCheck).times(1).returns(true)
    @comment.should be_spam
    @comment.should be_spam
  end

  it "should cache a negative spam? result" do
    Nex3::Akismet.expects(:commentCheck).times(1).returns(false)
    @comment.should_not be_spam
    @comment.should_not be_spam
  end

  it "should notify Akismet when spam! is declared" do
    Nex3::Akismet.expects(:submitSpam).with(*@akismet_info)
    @comment.spam!
  end

  it "should cache a spam! declaration" do
    Nex3::Akismet.stubs(:submitSpam)
    Nex3::Akismet.expects(:commentCheck).never
    @comment.spam!
    @comment.should be_spam
  end

  it "should notify Akismet when ham! is declared" do
    Nex3::Akismet.expects(:submitHam).with(*@akismet_info)
    @comment.ham!
  end

  it "should cache a ham! declaration" do
    Nex3::Akismet.stubs(:submitHam)
    Nex3::Akismet.expects(:commentCheck).never
    @comment.ham!
    @comment.should_not be_spam
  end

  it "shouldn't validate if it's spammy" do
    @comment = Comment.new(@comment.attributes)
    Nex3::Akismet.stubs(:submitSpam)
    @comment.spam!
    @comment.should have(1).error_on(:content)
  end
end
