require File.dirname(__FILE__) + '/../spec_helper'

describe Post, ".oldest" do
  fixtures :posts

  it "should return the oldest post" do
    Post.oldest.should == posts(:oldest)
  end

  it "should only select created_at and id" do
    Post.expects(:find).with(anything, has_entry(:select, 'created_at, id'))
    Post.oldest
  end
end

describe Post, ".newest" do
  fixtures :posts

  it "should return the newest post" do
    Post.newest.should == posts(:newest)
  end

  it "should only select created_at and id" do
    Post.expects(:find).with(anything, has_entry(:select, 'created_at, id'))
    Post.newest
  end
end

describe Post, ".after" do
  fixtures :posts

  it "should return the first post after the given date" do
    Post.after('2007-05-03 00:00:02').should == posts(:end)
  end

  it "should return the post after the given date even if a post with the exact date exists" do
    Post.after('2007-05-03 00:00:01').should == posts(:end)
  end
end

describe Post, ".before" do
  fixtures :posts

  it "should return the first post before the given date" do
    Post.before('2007-05-03 00:00:00').should == posts(:start)
  end

  it "should return the post before the given date even if a post with the exact date exists" do
    Post.before('2007-05-03 00:00:01').should == posts(:start)
  end
end

describe Post, ".between" do
  fixtures :posts

  it "should return all posts between the given dates" do
    Post.between('2007-05-01 00:00:00', '2007-05-05 00:00:02').should have(3).posts
  end

  it "should be backward-inclusive" do
    Post.between('2007-05-01 00:00:01', '2007-05-01 00:00:02').should include(posts(:start))
  end

  it "should be forward-exclusive" do
    Post.between('2007-05-05 00:00:00', '2007-05-05 00:00:01').should_not include(posts(:end))
  end

  it "should order by creation time, with the most recent post first" do
    posts = Post.between('2007-05-01 00:00:00', '2007-05-05 00:00:02')
    posts.should == posts.sort { |p1, p2| p2.created_at <=> p1.created_at }
  end
end

describe Post, ".months_spanned" do
  fixtures :posts

  before(:each) { @months = Post.months_spanned }

  it "should contain the first month" do
    @months[-1].month.should == 8
    @months[-1].year.should == 1990
  end

  it "should contain the last month" do
    @months[0].month.should == 8
    @months[0].year.should == 2010
  end

  it "should contain many months in between the first and last" do
    @months.should have_at_least((2010 - 1990) * 12).months
  end

  it "should be ordered by date descending" do
    @months.should == @months.sort.reverse
  end
end

describe Post, "with a normal configuration" do
  fixtures :posts

  it "should be valid" do
    posts(:first).should be_valid
  end

  it "should produce a unique uid" do
    posts(:first).uid.should == "http://nex-3.com,2007-04-02:1/"
  end
end

describe Post, "with an empty title" do
  fixtures :posts

  it "should have one error on title" do
    posts(:titleless).should have(1).error_on(:title)
  end
end

describe Post, "with empty content" do
  fixtures :posts

  it "should have one error on content" do
    posts(:contentless).should have(1).error_on(:content)
  end
end

describe Post, "with three comments" do
  fixtures :posts, :comments

  it "should have 3 comments" do
    posts(:commented).should have(3).comments
  end

  it "should have a collection of comments sorted by creation time, with the most recently posted last" do
    comments = posts(:commented).comments
    comments.should == comments.sort { |c1, c2| c1.created_at <=> c2.created_at }
  end

  it "should destroy its comments when it's destroyed" do
    posts(:commented).destroy
    lambda { comments(:one) }.should raise_error(ActiveRecord::RecordNotFound)
  end

  it "should have a comment_count of 3" do
    posts(:commented).comment_count.should == 3
  end

  it "should only calculate comment_count once" do
    Post.expects(:count_by_sql).returns(3).once
    5.times { posts(:commented).comment_count }
  end

  it "should load the comments' users if comments_with_users is called" do
    post = posts(:commented)
    comments = stub
    post.stubs(:comments).returns(comments)
    comments.expects(:find).with(:all, :include => :user)
    post.comments_with_users
  end
end

describe Post, "with three already-loaded comments" do
  fixtures :posts

  before :each do
    @post = posts(:commented)
    @post.comments(true)
  end

  it "should have a comment_count of 3" do
    @post.comment_count.should == 3
  end

  it "shouldn't make an SQL call to determine comment_count" do
    Post.expects(:count_by_sql).never
    @post.comment_count
  end
end

describe Post, "chronologically between two others" do
  fixtures :posts

  it "should return the next post when #next is called" do
    posts(:mid).next.should == posts(:end)
  end

  it "should return the previous post when #prev is called" do
    posts(:mid).prev.should == posts(:start)
  end
end

describe Post, "with formatted content" do
  fixtures :posts

  before(:each) { @rendered = posts(:redclothed).render }

  it "should format the content" do
    @rendered.should include('<strong>emphasis</strong>')
  end

  it "should make footnote links unique" do
    @rendered.should include('href="#post-10-fn1"')
    @rendered.should include('id="post-10-fn1"')
  end

  it "should give footnote paragraphs a 'footnote' class" do
    @rendered.should =~ /<p[^>]+class="footnote"[^>]*>/
  end
end

describe Post, "unsaved with formatted content" do
  fixtures :posts

  before(:each) do
    @rendered = Post.new(:content => "Footnote[1].\n\nfn1. Yes.").render
  end

  it "should make footnote links unique" do
    @rendered.should include('href="#post-new-fn1"')
    @rendered.should include('id="post-new-fn1"')
  end
end

describe Post, "with lots of content" do
  fixtures :posts

  it "should have lots of paragraphs" do
    posts(:complicated).should have_at_least(5).paragraphs
  end

  it "should render lots of paragraphs" do
    posts(:complicated).render.count("<p").should >= 5
  end

  it "should only render_small three paragraphs" do
    posts(:complicated).render_small.scan("<p").should have_at_most(3).occurrences
  end
end

describe Post, "ending with an image" do
  fixtures :posts

  it "shouldn't render_small the image" do
    posts(:imagey).render_small.should_not include("<img")
  end
end

describe Post, "with global syntax highlighting" do
  fixtures :posts

  it "should render_small four paragraphs" do
    posts(:syntaxey).render_small.should include("Skop.")
  end
end

describe Post, "with a couple tags" do
  fixtures :posts, :posts_tags, :tags

  it "should have the proper two tags, ordered alphabetically" do
    posts(:first).tags.should == [tags(:awesome), tags(:emacs)]
  end
end

describe Post, "#slug" do
  before :each do
    @post = Post.new
  end
  
  it "should downcase all capitals" do
    @post.stubs(:title).returns('FoObArIo')
    @post.slug.should == 'foobario'
  end

  it "should replace unrecognized characters with hyphens" do
    @post.stubs(:title).returns('f^o@o b.a*r&i~o')
    @post.slug.should == 'f-o-o-b-a-r-i-o'
  end

  it "shouldn't replace numbers with hyphens" do
    @post.stubs(:title).returns('foo15bario')
    @post.slug.should == 'foo15bario'
  end

  it "shouldn't replace underscores with hyphens" do
    @post.stubs(:title).returns('foo_bario')
    @post.slug.should == 'foo_bario'
  end

  it "should merge strings of hyphens into one" do
    @post.stubs(:title).returns('foo---b*&~a-#-rio')
    @post.slug.should == 'foo-b-a-rio'
  end

  it "should get rid of trailing hyphens" do
    @post.stubs(:title).returns('foobario-#-~')
    @post.slug.should == 'foobario'
  end
end
