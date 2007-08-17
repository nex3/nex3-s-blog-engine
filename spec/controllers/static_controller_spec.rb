require File.dirname(__FILE__) + '/../spec_helper'

describe StaticController, "#show" do
  before :each do
    @params = { :page => 'foobinus_bibbit_boo' }
  end

  it "should set the title to the page name" do
    controller.expects(:title).with(@params[:page].titleize)
    get :show, @params
  end

  it "should render the partial with the page name" do
    get :show, @params
    response.should render_template('_foobinus_bibbit_boo')
  end
end
