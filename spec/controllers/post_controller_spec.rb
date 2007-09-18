require File.dirname(__FILE__) + '/../spec_helper'

describe PostsController do
  before(:each) do
    @params = {}
    controller.stubs(:params).returns(@params)

    @tag = stub('Tag')
    Tag.stubs(:find).returns @tag
    @tag.stubs(:id).returns 12
  end

  it "should accept URLs with additional text" do
    controller.stubs(:params).returns(:id => "1-foo-bar-baz")
    Post.expects(:find).with(1)
    controller.send(:current_object)
  end

  it "should find at most six posts" do
    Post.expects(:find).with(anything, has_entry(:limit, 6))
    controller.send(:current_objects)
  end

  it "should order posts by creation time" do
    Post.expects(:find).with(anything, has_entry(:order, 'posts.created_at DESC'))
    controller.send(:current_objects)
  end

  it "should load comments and tags for the posts" do
    Post.expects(:find).with(anything, has_entry(:include, [:comments, :tags]))
    controller.send(:current_objects)
  end

  it "should search for posts if a query is given" do
    Post.expects(:find).with(:all, :order => 'posts.created_at DESC', :include => [:comments, :tags],
                             :conditions => ['posts.content LIKE ? OR posts.title LIKE ?',
                                             "%term%", "%term%"])
    @params[:query] = "term"
    controller.send(:current_objects)
  end

  it "should filter the posts if a tag is given" do
    Post.expects(:find).with(:all, :limit => 6, :order => 'posts.created_at DESC', :include => [:comments, :tags],
                             :limit => 6, :conditions => ['posts_tags.tag_id = ?', 12])
    @params[:tag] = "Stuff"
    Tag.expects(:find).with(:first, :conditions => {:name => 'stuff'}).returns(@tag)
    controller.send(:current_objects)
  end

  it "should filter search results if both a tag and a query are given" do
    Post.expects(:find).with(:all, :order => 'posts.created_at DESC', :include => [:comments, :tags],
                             :conditions => ['posts_tags.tag_id = ? AND (posts.content LIKE ? OR posts.title LIKE ?)',
                                             12, "%term%", "%term%"])
    @params[:query] = "term"
    @params[:tag] = "stuff"
    controller.send(:current_objects)
  end
end

describe PostsController, "#date_link" do
  include ResourcefulController

  before :each do
    controller.stubs(:url_for)
    controller.stubs(:params).returns({})

    stub_view

    @post = stub(:created_at => Date.new(1990, 8, 11))
  end

  it "should find the next month's URL if month is specified" do
    controller.stubs(:params).returns(:month => '8')
    controller.expects(:url_for).with(:action => :dates, :year => 1990, :month => 8)
    controller.send(:date_link, @post, '', true)
  end

  it "should find the next year's URL if month isn't specified" do
    controller.expects(:url_for).with(:action => :dates, :year => 1990, :month => nil)
    controller.send(:date_link, @post, '', true)
  end

  it "should use the 'book_next' icon for the 'Next' link" do
    @view.expects(:silk_tag).with('book_next', :alt => 'Next')
    controller.send(:date_link, @post, '', false)
  end

  it "should use the 'book_previous' icon for the 'Previous' link" do
    @view.expects(:silk_tag).with('book_previous', :alt => 'Previous')
    controller.send(:date_link, @post, '', true)
  end

  it "should include the formatted date" do
    @view.expects(:link_to).with(includes( 'August 1990'), anything)
    controller.send(:date_link, @post, '%B %Y', true)
  end

  it "should have the date before the icon for the 'Next' link" do
    @view.expects(:silk_tag).returns('ICON')
    @view.expects(:link_to).with { |text, url| text =~ /August 1990\s*ICON/ }
    controller.send(:date_link, @post, '%B %Y', false)
  end

  it "should have the date after the icon for the 'Previous' link" do
    @view.expects(:silk_tag).returns('ICON')
    @view.expects(:link_to).with { |text, url| text =~ /ICON\s*August 1990/ }
    controller.send(:date_link, @post, '%B %Y', true)
  end
end

describe PostsController, "#index" do
  include ResourcefulController
  before(:each) { stub_index }

  it "should render the html template on an html request" do
    get :index, :format => 'html'
    response.should render_template("index")
  end

  it "should render the atom template on an atom request" do
    get :index, :format => 'atom'
    response.should render_template("index_atom")
  end

  it "should render the atom template with the proper content-type" do
    get :index, :format => 'atom'
    response.headers['Content-Type'].should == 'application/atom+xml; charset=utf-8'
  end

  it "should set the title for index with a query" do
    controller.expects(:title).with("Search results for \"foobar\"")
    get :index, :query => 'foobar'
  end

  it "should set the title for index with a tag" do
    controller.expects(:title).with("Posts about Stuff")
    get :index, :tag => 'stuff'
  end
end

describe PostsController, "#show" do
  include ResourcefulController
  before(:each) { stub_show }

  it "should set the page title to the post's title" do
    @post.stubs(:title).returns("Foo Bar Blitzen!")
    get :show, :id => 42
    assigns[:page_title].should == "Foo Bar Blitzen!"
  end
end

describe PostsController, "#new" do
  include ResourcefulController
  include ApplicationSpecHelpers
  before(:each) { stub_new }

  it "should redirect to signin for a non-admin" do
    get :new
    response.should redirect_to('/signin')
  end

  it "should render the new post form for an admin" do
    set_admin
    get :new, :format => 'html'
    response.should render_template('edit')
  end

  it "should set the page title to 'New Post'" do
    set_admin
    get :new
    assigns[:page_title].should == 'New Post'
  end

  it "should render Javascript when called with format 'js'" do
    set_admin
    get :new, :format => 'js'
    response.headers['Content-Type'].should == 'text/javascript; charset=utf-8'
  end
end

describe PostsController, "#edit" do
  include ResourcefulController
  include ApplicationSpecHelpers
  before(:each) { stub_edit }

  it "should redirect to signin for a non-admin" do
    get :edit, :id => 42
    response.should redirect_to('/signin')
  end

  it "should render the edit post form for an admin" do
    set_admin
    @post.stubs(:title)
    get :edit, :id => 42
    response.should render_template('edit')
  end

  it 'should set the page title to \'Editing "#{@post.name}"\'' do
    set_admin
    @post.stubs(:title).returns('Bilspickets')
    get :edit, :id => 42
    assigns[:page_title].should == 'Editing "Bilspickets"'
  end
end

describe PostsController, "#update" do
  include ResourcefulController
  include ApplicationSpecHelpers
  before(:each) { stub_update }

  it "should redirect to signin for a non-admin" do
    put :update, :id => 1
    response.should redirect_to('/signin')
  end

  it "should redirect to #show for an admin" do
    set_admin
    controller.stubs(:post_path).returns('/posts/1-best-post-ever')
    put :update, :format => 'html', :id => 1
    response.should redirect_to('/posts/1-best-post-ever')
  end
end

describe PostsController, "#create" do
  include ResourcefulController
  include ApplicationSpecHelpers
  before(:each) { stub_create }

  it "should redirect to signin for a non-admin" do
    post :create
    response.should redirect_to('/signin')
  end

  it "should redirect to #show for an admin" do
    set_admin
    controller.stubs(:post_path).returns('/posts/1-best-post-ever')
    post :create, :format => 'html'
    response.should redirect_to('/posts/1-best-post-ever')
  end
end

describe PostsController, "#destroy" do
  include ResourcefulController
  include ApplicationSpecHelpers
  before(:each) { stub_destroy }

  it "should redirect to signin for a non-admin" do
    delete :destroy, :format => 'html', :id => 42
    response.should redirect_to('/signin')
  end

  it "should redirect to #show for an admin" do
    set_admin
    delete :destroy, :format => 'html', :id => 42
    response.should redirect_to('/posts')
  end
end

describe PostsController, "#dates" do
  include ResourcefulController

  before :each do
    @after = stub
    Post.stubs(:after).returns(@after)

    @before = stub(:created_at => Date.new(1990, 7, 26))
    Post.stubs(:before).returns(@before)

    Post.stubs(:between)
    controller.stubs(:date_link)
  end

  it "should redirect to index if no year is specified" do
    get :dates
    response.should redirect_to('/posts')
  end

  it "should set the title to the month and year if possible" do
    get :dates, :year => 1918, :month => 8
    assigns[:page_title].should == 'August 1918'
  end

  it "should set the title to the year if no month is specified" do
    get :dates, :year => 1918
    assigns[:page_title].should == '1918'
  end

  it "should look for the first post after the current month" do
    Post.expects(:after).with(Date.new(1918, 9, 1).to_time)
    get :dates, :year => 1918, :month => 8
  end

  it "should look for the last post before the current month" do
    Post.expects(:before).with(Date.new(1918, 8, 1).to_time)
    get :dates, :year => 1918, :month => 8
  end

  it "should look for all posts in the current month" do
    Post.expects(:between).with(*[Date.new(1918, 8, 1), Date.new(1918, 9, 1)].map(&:to_time))
    get :dates, :year => 1918, :month => 8
  end

  it "should construct a 'Next' link to the next month if month is specified" do
    controller.expects(:date_link).with(@after, '%B %Y', false)
    get :dates, :year => 1918, :month => 8
  end

  it "should construct a 'Next' link to the next year if month isn't specified" do
    controller.expects(:date_link).with(@after, '%Y', false)
    get :dates, :year => 1918
  end

  it "should construct a 'Previous' link to the previous month if month is specified" do
    controller.expects(:date_link).with(@before, '%B %Y', true)
    get :dates, :year => 1918, :month => 8
  end

  it "should construct a 'Previous' link to the previous year if month isn't specified" do
    controller.expects(:date_link).with(@before, '%Y', true)
    get :dates, :year => 1918
  end
end
