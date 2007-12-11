require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController, "#index with a post" do
  include ResourcefulController
  before(:each) do
    stub_view
    stub_env
    @post = stub
    Post.stubs(:find).returns(@post)
  end

  it "should redirect to the comments section of the appropriate post for an HTML request" do
    @post.stubs(:slug).returns("foobario")
    @post.stubs(:to_param).returns("16")

    get :index, :post_id => 16
    response.should redirect_to('/posts/16-foobario#comments')
  end

  it "should display the ATOM feed for an ATOM request" do
    controller.stubs(:load_objects)
    controller.expect_render(:action => 'index', :layout => false)

    get :index, :post_id => 16, :format => 'atom'
    response.headers['type'].should == 'application/atom+xml; charset=utf-8'
  end

  it "should only find 10 comments scoped by the given post, including users, and order them by created_at DESC for ATOM" do
    comments = stub("@post.comments")
    @post.stubs(:comments).returns(comments)
    comments.expects(:find).with(:all, :order => 'comments.created_at DESC', :limit => 10, :include => :user)

    get :index, :post_id => 16, :format => 'atom'
  end
end

describe CommentsController, "#index without a post" do
  include ResourcefulController
  before(:each) do
    stub_view
    stub_env
  end

  it "should redirect to / for an HTML request" do
    get :index
    response.should redirect_to('/')
  end

  it "should find the comments from the Comment model" do
    Comment.expects(:find).with(:all, anything)
    get :index, :format => 'atom'
  end
end

describe CommentsController, "#create" do
  include ResourcefulController

  before(:each) do
    @parent_model = Post
    stub_create

    @params = {
      :post_id => 42,
      :user => {
        :name => "Bobbehrt",
        :link => "http://google.com",
        :email => "bobbert@bobbert.org"
      }.stringify_keys,
      :comment => {:content => "HA HA HA"}
    }

    @user = User.new @params[:user]
    User.stubs(:new).returns(@user)

    @comment.stubs(:user=)
    @comment.stubs(:id).returns(12)

    @post.stubs(:to_param).returns('42')
    @post.stubs(:slug).returns('bababa')
  end

  it "should construct a new User instance" do
    User.expects(:new).with(all_of(*@params[:user].map(&method(:has_entry)))).returns(@user)
    post :create, @params
  end

  it "should check a newly created user to see if it's actually the current user" do
    controller.expects(:current_user_if_same).with(@user).returns(@user)
    post :create, @params
  end

  it "should set the comment's user" do
    @comment.expects(:user=).with(@user)
    post :create, @params
  end

  it "should set the current user if the create succeeds" do
    controller.expects(:current_user=).with(@user)
    post :create, @params
  end

  it "shouldn't set the current user if the create fails" do
    controller.expects(:current_user=).never
    @comment.stubs(:save).returns(false)
    post :create, @params
  end  

  it "should look up the URL of the proper post if the create succeeds" do
    controller.expects(:post_path).with(@post).returns('')
    post :create, @params
  end

  it "should redirect to the given comment and the proper post URL if the create succeeds" do
    post :create, @params
    response.should redirect_to('http://test.host/posts/42-bababa#comment_12')
  end

  it "should redirect back if the create fails" do
    @comment.stubs(:save).returns(false)
    post :create, @params
    response.should redirect_to('http://back.host/')
  end

  it "shouldn't mark the comment as spam if params[:email] is empty" do
    @params[:email] = ""
    @comment.expects(:spam!).never
    post :create, @params
  end

  it "should mark the comment as spam if params[:email] is filled in" do
    @params[:email] = "foo@bar.com"
    @comment.expects(:spam!)
    post :create, @params
  end

  it "should redirect to / if there's no post_id" do
    @params.delete :post_id
    post :create, @params
    response.should redirect_to('/')
  end
end

describe CommentsController, "#new" do
  include ResourcefulController

  before(:each) do
    @parent_model = Post
    stub_new

    @params = {:post_id => 42}

    @comment.stubs(:user).returns(nil)
    @comment.stubs(:user=)
  end

  it "should check the comment's user to see if it's the current user if user_id isn't specified" do
    controller.expects(:current_user_if_same)
    get :new, @params
  end

  it "shouldn't check the comment's user to see if it's the current user if user_id is specified" do
    @comment.stubs(:user).returns(stub)
    controller.expects(:current_user_if_same).never
    get :new, @params
  end

  it "should redirect to / if there's no post_id" do
    @params.delete :post_id
    post :new, @params
    response.should redirect_to('/')
  end
end

describe CommentsController, "#update" do
  include ResourcefulController
  include ApplicationSpecHelpers

  before :each do
    @parent_model = Post
    stub_update

    @params = {
      :post_id => 42,
      :id => 12,
      :format => 'js',
      :comment => {:content => "HO HO HO"}
    }

    @comment.stubs(:user).returns(stub)
  end

  it "should redirect to signin for an improper user" do
    post :update, @params
    response.should redirect_to('/signin')
  end

  it "should render the update javascript for a proper user" do
    set_proper
    post :update, @params
    response.should render_template('update')
  end
end

describe CommentsController, "#destroy" do
  include ResourcefulController
  include ApplicationSpecHelpers

  before :each do
    @parent_model = Post
    stub_destroy

    @params = {
      :post_id => 42,
      :id => 12
    }

    @post.stubs(:to_param).returns('42')
    @post.stubs(:slug).returns('horbit')

    @comment.stubs(:user).returns(stub)
  end

  it "should redirect to signin for an improper user" do
    post :destroy, @params
    response.should redirect_to('/signin')
  end

  it "should redirect to the post for a proper user" do
    set_proper
    post :destroy, @params
    response.should redirect_to('http://test.host/posts/42-horbit#comments')
  end

  it "should mark the comment as spam if the spam param is set" do
    set_proper
    @params[:spam] = '1'
    @comment.expects(:spam!)
    post :destroy, @params
  end
end

describe CommentsController, "#edit" do
  include ResourcefulController
  include ApplicationSpecHelpers

  before :each do
    @parent_model = Post
    stub_edit

    @params = {
      :post_id => 42,
      :format => 'js',
      :id => 12
    }

    @comment.stubs(:user).returns(stub)
  end

  it "should redirect to signin for an improper user" do
    post :edit, @params
    response.should redirect_to('/signin')
  end

  it "should redirect to the post for a proper user" do
    set_proper
    post :edit, @params
    response.should render_template('edit')
  end
end
