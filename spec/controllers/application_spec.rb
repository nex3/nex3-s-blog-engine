require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController, ".title" do

  # For some reason, the before_filter block doesn't get called,
  # even when we assign an actual controller and make a request.
  # Thus, a lot of this stuff isn't actually testable
  it "should set @page_title before an action"
end

describe ApplicationController, "#title" do
  include ApplicationSpecHelpers

  controller_name :posts

  before(:each) { publicize_helpers }

  it "should set @page_title" do
    controller.title "Foobinius"
    get :index
    assigns(:page_title).should == "Foobinius"
  end
end

describe ApplicationController, "#view" do
  include ApplicationSpecHelpers

  controller_name :posts

  before(:each) do
    publicize_helpers

    controller.stubs(:response).returns(stub('response', :template => stub('response.template')))
  end

  it "should return response.template" do
    controller.view.should == controller.response.template
  end

  it "should set response.template's singular instance variable on a singular action" do
    @post = stub('@post')

    controller.instance_variable_set("@post", @post)
    controller.stubs(:current_object).returns(@post)

    controller.response.template.expects(:instance_variable_set).with('@post', @post)

    controller.view
  end

  it "should set response.template's plural instance variable on a plural action" do
    @posts = stub('@posts')

    controller.instance_variable_set("@posts", @posts)
    controller.stubs(:current_objects).returns(@posts)

    controller.response.template.expects(:instance_variable_set).with('@posts', @posts)

    controller.view
  end

  it "shouldn't set any instance variables if the action is ambiguous" do
    controller.response.template.expects(:instance_variable_set).never
    controller.view
  end
end

describe ApplicationController, "#comments_path" do
  include ResourcefulController
  include ApplicationSpecHelpers

  controller_name :posts

  before :each do
    stub_index
    get :index

    publicize_helpers

    @post = stub('@post', :to_param => '42')
  end

  it "should follow post_path with a #comments anchor" do
    @post.stubs(:slug).returns('foobario')
    controller.comments_path(@post).should == "/posts/42-foobario#comments"
  end
end

describe ApplicationController, "#post_path" do
  include ResourcefulController
  include ApplicationSpecHelpers

  controller_name :posts

  before :each do
    stub_index
    get :index

    publicize_helpers

    @post = stub('@post', :to_param => '42')
  end

  it "should follow the normal post path with the slug" do
    @post.stubs(:slug).returns('foobario')
    controller.post_path(@post).should == '/posts/42-foobario'
  end
end

describe ApplicationController, "#post_url" do
  include ResourcefulController
  include ApplicationSpecHelpers

  controller_name :posts

  before :each do
    stub_index
    get :index

    publicize_helpers

    @post = stub('@post', :to_param => '42')
  end

  it "should follow the normal post url with the slug" do
    @post.stubs(:slug).returns('foobario')
    controller.post_url(@post).should == 'http://test.host/posts/42-foobario'
  end
end

describe ApplicationController, "#params" do
  include ApplicationSpecHelpers

  before :each do
    publicize_helpers

    @params = {}
    controller.stubs(:params_without_ip_and_agent).returns(@params)

    @request = stub
    controller.stubs(:request).returns(@request)
    @request.stubs(:remote_ip).returns("127.0.0.1")
    @request.stubs(:env).returns({'HTTP_USER_AGENT' => 'Foobar', 'HTTP_REFERRER' => 'http://www.google.com'})
  end

  it "should set the user's ip" do
    @params[:user] = {}
    controller.params[:user].should be_a_kind_of(Hash)
    controller.params[:user][:ip].should == "127.0.0.1"
  end

  it "should set the user's agent" do
    @params[:user] = {}
    controller.params[:user].should be_a_kind_of(Hash)
    controller.params[:user][:agent].should == "Foobar"
  end

  it "should set the user's referrer" do
    @params[:user] = {}
    controller.params[:user].should be_a_kind_of(Hash)
    controller.params[:user][:referrer].should == 'http://www.google.com'
  end

  it "shouldn't set anything if user isn't set" do
    controller.params[:user].should be_nil
  end
end

describe ApplicationController, "#current_user=" do
  include ApplicationSpecHelpers

  before :each do
    publicize_helpers

    controller.stubs(:session).returns({})
    controller.stubs(:cookies).returns({})

    @user = stub('@user', :id => 42)
  end

  it "should set session[:user_id]" do
    controller.current_user = @user
    controller.session[:user_id].should == @user.id
  end

  it "should set cookies[:user_id]'s value if it hasn't yet been set" do
    controller.current_user = @user
    controller.cookies[:user_id][:value].should == @user.id.to_s
  end

  it "should set cookies[:user_id]'s expiration to a week from now" do
    controller.current_user = @user
    controller.cookies[:user_id][:expires].to_date.should == 1.week.from_now.to_date
  end

  it "should set cookies[:user_id]'s value if it's different than the current user's id" do
    controller.cookies[:user_id] = {:value => @user.id - 1}
    controller.current_user = @user
    controller.cookies[:user_id][:value].should == @user.id.to_s
  end

  it "shouldn't set cookies[:user_id]'s value if it's the same as the current user's id" do
    controller.cookies[:user_id] = {:value => @user.id}
    controller.cookies.expects(:[]=).never
    controller.current_user = @user
  end
end

describe ApplicationController, "#current_user" do
  include ApplicationSpecHelpers

  before :each do
    publicize_helpers

    @user = stub('@user')
    User.stubs(:find).returns(@user)

    @anon = stub('@anon')
    User.stubs(:anon).returns(@anon)

    controller.stubs(:current_user=)
    controller.stubs(:session).returns({})
    controller.stubs(:cookies).returns({})
    controller.stubs(:params).returns({})
  end

  it "should return the current user" do
    controller.session[:user_id] = 42
    controller.current_user.should == @user
  end

  it "should set the current user to that specified in the session if it exists" do
    controller.session[:user_id] = 42
    User.expects(:find).with(42)
    controller.current_user
  end

  it "should set the current user to that specified in the cookies if it exists" do
    controller.cookies[:user_id] = 42
    User.expects(:find).with(42)
    controller.current_user
  end

  it "should set the current user to that specified in the session if specified in both the session and the cookies" do
    controller.session[:user_id] = 42
    controller.cookies[:user_id] = 43
    User.expects(:find).with(42)
    controller.current_user
  end

  it "should set the current user to an anonymous user if it's not specified" do
    controller.current_user.should == @anon
  end

  it "should return @current_user if it's set" do
    controller.instance_variable_set('@current_user', 42)
    controller.current_user.should == 42
  end

  it "should try to log in the user given by params[:admin][:name and :pass] if they exist" do
    controller.stubs(:params).returns(:admin => {:name => "Foob", :pass => "Barf"})
    User.expects(:login).with("Foob", "Barf").returns(:user)
    controller.current_user.should == :user
  end

  it "should raise an error if params[:admin][:name] is given but params[:admin_pass] isn't" do
    controller.stubs(:params).returns(:admin => {:name => "Foob"})
    lambda { controller.current_user }.should raise_error
  end

  it "should raise an error if params[:admin_name] and params[:admin_pass] are invalid" do 
    controller.stubs(:params).returns(:admin => {:name => "Foob", :pass => "Barf"})
    User.stubs(:login).returns(nil)
    lambda { controller.current_user }.should raise_error
  end
end

describe ApplicationController, "#current_user_if_same" do
  include ApplicationSpecHelpers

  before :each do
    publicize_helpers

    @user = stub('@user', :name => 'a', :link => 'b', :email => 'c')

    @current_user = stub('@current_user', :name => 'd', :link => 'e', :email => 'f')
    controller.stubs(:current_user).returns(@current_user)
  end

  it "should return current_user if name, link, and email match up" do
    @current_user.stubs(:name).returns('a')
    @current_user.stubs(:link).returns('b')
    @current_user.stubs(:email).returns('c')
    controller.current_user_if_same(@user).should == @current_user
  end

  it "should return the given user if name, link, and email don't match up" do
    controller.current_user_if_same(@user).should == @user
  end

  it "should return the given user if name, link, or email don't match up" do
    @current_user.stubs(:name).returns('a')
    @current_user.stubs(:link).returns('b')
    controller.current_user_if_same(@user).should == @user
  end
end

describe ApplicationController, "#admin?" do
  include ApplicationSpecHelpers
  before :each do
    publicize_helpers

    @user = stub('@user')
    controller.stubs(:current_user).returns(@user)
  end

  it "should return true if the current user is an admin" do
    @user.stubs(:admin?).returns(true)
    controller.admin?.should == true
  end

  it "should return false if the current user is not an admin" do
    @user.stubs(:admin?).returns(false)
    controller.admin?.should == false
  end
end

describe ApplicationController, "#proper?" do
  include ApplicationSpecHelpers
  before :each do
    publicize_helpers

    @user = stub('@user')
    controller.stubs(:current_user).returns(@user)

    @object = stub('@object')
    controller.stubs(:current_object).returns(@object)
  end

  it "should return true if the current user is the same as the current object's user" do
    @object.stubs(:user).returns(@user)
    controller.proper?.should == true
  end

  it "should return false if the current user isn't the same as the current object's user" do
    @object.stubs(:user).returns(stub)
    controller.proper?.should == false
  end
end

describe ApplicationController, "#require_admin" do
  include ApplicationSpecHelpers

  before(:each) do
    publicize_helpers
    
    controller.stubs(:force_signin).returns(false)
  end

  it "should force signin if the user isn't an admin" do
    controller.stubs(:admin?).returns(false)
    controller.expects(:force_signin)
    controller.require_admin
  end

  it "shouldn't force signin if the user is an admin" do
    controller.stubs(:admin?).returns(true)
    controller.expects(:force_signin).never
    controller.require_admin
  end

  it "should return false if the user isn't an admin" do
    controller.stubs(:admin?).returns(false)
    controller.require_admin.should == false
  end

  it "shouldn't return false if the user is an admin" do
    controller.stubs(:admin?).returns(true)
    controller.require_admin.should_not == false
  end
end

describe ApplicationController, "#require_proper_user" do
  include ApplicationSpecHelpers
  before(:each) do
    publicize_helpers

    controller.stubs(:force_signin).returns(false)
  end

  it "should force signin if the user is neither an admin nor the proper user" do
    controller.stubs(:admin?).returns(false)
    controller.stubs(:proper?).returns(false)
    controller.expects(:force_signin)
    controller.require_proper_user
  end

  it "shouldn't force signin if the user is an admin" do
    controller.stubs(:admin?).returns(true)
    controller.stubs(:proper?).returns(false)
    controller.expects(:force_signin).never
    controller.require_proper_user
  end

  it "shouldn't force signin if the user is the proper user" do
    controller.stubs(:admin?).returns(false)
    controller.stubs(:proper?).returns(true)
    controller.expects(:force_signin).never
    controller.require_proper_user
  end

  it "should return false if the user is neither an admin nor the proper user" do
    controller.stubs(:admin?).returns(false)
    controller.stubs(:proper?).returns(false)
    controller.require_proper_user.should == false
  end

  it "shouldn't return false if the user is an admin" do
    controller.stubs(:admin?).returns(true)
    controller.stubs(:proper?).returns(false)
    controller.require_proper_user.should_not == false
  end

  it "shouldn't return false if the user is the proper user" do
    controller.stubs(:admin?).returns(false)
    controller.stubs(:proper?).returns(true)
    controller.require_proper_user.should_not == false
  end
end

describe ApplicationController, "#force_signin" do
  include ApplicationSpecHelpers
  before(:each) do
    publicize_helpers

    controller.stubs(:session).returns({})
    controller.stubs(:request).returns(stub('request', :request_uri => 'REQUEST_URI'))
    controller.stubs(:redirect_to)
  end

  it "should set session[:intended] to the request URI" do
    controller.force_signin
    controller.session[:intended].should == 'REQUEST_URI'
  end

  it "should redirect to /signin" do
    controller.expects(:redirect_to).with(:controller => 'signin', :action => 'new')
    controller.force_signin
  end

  it "should return false" do
    controller.force_signin.should == false
  end
end
