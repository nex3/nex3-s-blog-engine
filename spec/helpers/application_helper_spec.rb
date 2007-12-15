require File.dirname(__FILE__) + '/../spec_helper'


describe RestfulFormWrapper do
  include Haml::Helpers

  before :each do
    init_haml_helpers
    @form_builder = stub_everything
    @wrapper = RestfulFormWrapper.new(self, @form_builder)

    stubs(:instance_variable_name).returns('people')
    stubs(:open).yields
  end

  it "should pass on method calls to the form_builder" do
    @form_builder.expects(:text_field).with(:name)
    @wrapper.text_field(:name)
  end

  it "should open a div" do
    expects(:open).with('div', anything)
    @wrapper.text_field(:name)
  end

  it "should open a div with class set to the field" do
    expects(:open).with('div', has_entry(:class, 'name'))
    @wrapper.text_field(:name)
  end

  it "should open a div with id set to the field" do
    expects(:open).with('div', has_entry(:id, 'name_field'))
    @wrapper.text_field(:name)
  end

  it "should open a label" do
    stubs(:open).with(anything, anything).yields
    expects(:open).with('label', anything, anything)
    @wrapper.text_field(:name)
  end

  it "should open a label with the titleized field by default" do
    stubs(:open).with(anything, anything).yields
    expects(:open).with('label', 'Thing Name', anything)
    @wrapper.text_field(:thing_name)
  end

  it "should open a label with options[:label] if given" do
    stubs(:open).with(anything, anything).yields
    expects(:open).with('label', 'Fooberino', anything)
    @wrapper.text_field(:name, :label => 'Fooberino')
  end

  it "should open a label with 'for' containing the singularized instance_variable_name and the field" do
    stubs(:open).with(anything, anything).yields
    expects(:open).with('label', anything, has_entry(:for, 'person_name'))
    @wrapper.text_field(:name)
  end

  it "should run find_and_preserve over form_builder output" do
    @form_builder.stubs(:text_area).returns("<textarea>  Foo\n  Bar</textarea>")
    expects(:find_and_preserve).with("<textarea>  Foo\n  Bar</textarea>")
    @wrapper.text_area(:name)
  end

  it "should output the result of find_and_preserve to the template" do
    @form_builder.stubs(:text_field).returns("<input>Stuff</input>")
    expects(:puts).with("<input>Stuff</input>")
    @wrapper.text_field(:name)
  end
end


describe ApplicationHelper, "#restful_form" do
  before :each do
    stubs(:objects_path).returns('/people')
    stubs(:object_path).returns('/person/15')
    stubs(:instance_variable_name).returns('people')

    @form_builder = stub
    stubs(:form_for).yields(@form_builder)
  end

  it "should pass the singular instance_variable_name to form_for" do
    expects(:form_for).with('person', anything)
    restful_form
  end

  it "should set url to objects_path if the action is 'new'" do
    stubs(:params).returns(:action => 'new')
    expects(:form_for).with(anything, has_entry(:url, '/people'))
    restful_form
  end

  it "should set url to object_path if the action is 'edit'" do
    stubs(:params).returns(:action => 'edit')
    expects(:form_for).with(anything, has_entry(:url, '/person/15'))
    restful_form
  end

  it "shouldn't set method if action is 'new'" do
    stubs(:params).returns(:action => 'new')
    expects(:form_for).with(anything, has_entry(:html, {}))
    restful_form
  end

  it "should set method to :put if action is 'new'" do
    stubs(:params).returns(:action => 'edit')
    expects(:form_for).with(anything, has_entry(:html, {:method => :put}))
    restful_form
  end

  it "should create a new RestfulFormWrapper" do
    RestfulFormWrapper.expects(:new)
    restful_form {}
  end

  it "should create a new RestfulFormWrapper with the current context" do
    RestfulFormWrapper.expects(:new).with(self, anything)
    restful_form {}
  end

  it "should create a new RestfulFormWrapper with the FormBuilder" do
    RestfulFormWrapper.expects(:new).with(anything, @form_builder)
    restful_form {}
  end

  it "should pass the RestfulFormWrapper to the block" do
    wrapper = stub
    RestfulFormWrapper.expects(:new).returns(wrapper)
    restful_form { |f| f.should == wrapper}
  end
end


describe ApplicationHelper, "#silk_tag" do
  it "should call image_tag with the silk icon location" do
    expects(:image_tag).with("silk/foo.png", anything)
    silk_tag 'foo'
  end

  it "should pass options on to image_tag" do
    expects(:image_tag).with(anything, :alt => 'Foo!', :bar => 'Baz')
    silk_tag 'foo', :alt => 'Foo!', :bar => 'Baz'
  end
end


describe ApplicationHelper, "#flash_display" do
  before :each do
    stubs(:flash).returns(:notice => "Yay!", :error => "Boo!")
    stubs(:open)
  end

  it "should create a div to display the message" do
    expects(:open).with('div', 'Yay!', :class => 'notice')
    flash_display
  end

  it "should create a div for each message" do
    expects(:open).times(2)
    flash_display
  end
end


describe ApplicationHelper, "#absolute_anchors" do
  it "should prepend footnotes in text with url" do
    absolute_anchors("<a href=\"#baz\">baz</baz>", "/page").should ==
      "<a href=\"/page#baz\">baz</baz>"
  end

  it "should respect single quoted attributes" do
    absolute_anchors("<a href='#baz'>baz</baz>", "/page").should ==
      "<a href='/page#baz'>baz</baz>"
  end
end


describe ApplicationHelper, "#preview_button" do
  it "should create a Preview button" do
    expects(:submit_to_remote).with('submit', 'Preview',
                                    has_entry(:html, {:class => 'button'}))
    preview_button("path", "el")
  end

  it "should POST the given path in Javascript format" do
    expects(:submit_to_remote).with(anything, anything,
                                    all_of(has_entry(:url, "path.js"),
                                           has_entry(:method, :post)))
    preview_button("path", "el")
  end

  it "should display a loading spinner" do
    expects(:submit_to_remote).with(anything, anything,
                                    has_entry(:loading, '$("el").spin()'))
    preview_button("path", "el")
  end

  it "should update the element with a failure message if the AJAX fails" do
    expects(:submit_to_remote).with(anything, anything,
                                    has_entry(:failure,
                                              '$("el").update("<h3 class=\'failure\'>Preview Failed</h3>")'))
    preview_button("path", "el")
  end

  it "should Javascript-escape the element name" do
    stubs(:submit_to_remote)
    element = mock
    element.expects(:to_json).times(2)
    preview_button("path", element)
  end
end

describe ApplicationHelper, "#xml_stylesheet" do
  it "should return an XML stylesheet declaration" do
    expects(:stylesheet_path).with("name").returns("/path/to/name.css")
    xml_stylesheet("name").should == "<?xml-stylesheet href=\"http://#{Nex3::Config['blog']['site']}/path/to/name.css\" type=\"text/css\" ?>"
  end
end
