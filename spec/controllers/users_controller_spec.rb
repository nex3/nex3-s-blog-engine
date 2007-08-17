require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController, "#update" do
  include ResourcefulController
  include ApplicationSpecHelpers

  before(:each) { stub_update }

  it "should redirect to the new user path on success if admin" do
    set_admin
    put :update, :id => 1
    response.should redirect_to(users_path)
  end

  it "should redirect to signin if not admin" do
    put :update, :id => 1
    response.should redirect_to('/signin')
  end
end

describe UsersController, "#index" do
  include ResourcefulController
  include ApplicationSpecHelpers

  before(:each) { stub_update }

  it "should render the index template if admin" do
    set_admin
    get :index
    response.should render_template('index')
  end

  it "should redirect to signin if not admin" do
    get :index
    response.should redirect_to('/signin')
  end

  it "should set the title to 'Manage Users'" do
    set_admin
    get :index
    assigns(:page_title).should == 'Manage Users'
  end
end

describe UsersController, "#current_objects" do
  it "should sort by count" do
    User.expects(:all_sorted_by_count)
    controller.current_objects
  end
end
