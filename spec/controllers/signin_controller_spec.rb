require File.dirname(__FILE__) + '/../spec_helper'

describe SigninController, "#create" do
  before :each do
    @params = {
      :name => 'Foobish',
      :pass => 'Fibbish'
    }

    @user = stub('@user')
    User.stubs(:login).returns(@user)

    controller.stubs(:current_user=)
  end

  it "should attempt to log the user in" do
    User.expects(:login).with(@params[:name], @params[:pass])
    post :create, @params
  end

  it "should set the current user if login is successful" do
    controller.expects(:current_user=).with(@user)
    post :create, @params
  end

  it "should notify the user when they are successfully signed in" do
    post :create, @params
    flash[:notice].should_not be_nil
    flash[:notice].should_not be_empty

    flash[:error].should be_nil
  end

  it "should redirect to the intended URL if possible on success" do
    controller.session[:intended] = 'http://intended.host/'
    post :create, @params
    response.should redirect_to('http://intended.host/')
  end

  it "should redirect to / if there is no intended URL on success" do
    post :create, @params
    response.should redirect_to('/')    
  end

  it "should reset the intended URL" do
    controller.session[:intended] = 'http://intended.host/'
    post :create, @params
    controller.session[:intended].should be_nil
  end

  it "should set an error message on failure" do
    User.stubs(:login).returns(nil)
    post :create, @params
    flash[:error].should_not be_nil
    flash[:error].should_not be_empty

    flash[:notice].should be_nil
  end

  it "should redirect to #new on failure" do
    User.stubs(:login).returns(nil)
    post :create, @params
    response.should redirect_to('/signin')
  end
end

describe SigninController, "#destroy" do
  it "should reset the User stored in the session" do
    controller.stubs(:session).returns(:user => 'Foobius')
    post :destroy
    controller.session[:user_id].should be_nil
  end

  it "should reset the User stored in a cookie" do
    controller.stubs(:cookies).returns(:user_name => 'Foobius')
    post :destroy
    controller.cookies[:user_id].should be_nil
  end

  it "should display a notice" do
    post :destroy
    flash[:notice].should_not be_nil
    flash[:notice].should_not be_empty
  end

  it "should redirect home" do
    post :destroy
    response.should redirect_to('/')
  end
end
