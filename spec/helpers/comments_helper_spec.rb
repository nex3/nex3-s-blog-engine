require File.dirname(__FILE__) + '/../spec_helper'


describe CommentsHelper, "#comment_edit_save_button" do
  before :each do
    @comment = stub
    @comment.stubs(:id).returns(12)
    stubs(:object_path).returns("/path/to/object")
  end

  it "should create a save button" do
    expects(:submit_to_remote).with('submit', 'Save',
                                    has_entry(:html, :class => 'button'))
    comment_edit_save_button
  end

  it "should PUT the content of the comment to the Javascript representation of the comment's path" do
    expects(:submit_to_remote).with(anything, anything,
                                    all_of(has_entry(:url, "/path/to/object.js"),
                                           has_entry(:method, :put),
                                           has_entry(:submit, "comment_12_content_field")))
    comment_edit_save_button
  end


  it "should display a loading spinner" do
    expects(:submit_to_remote).with(anything, anything,
                                    has_entry(:loading, '$(\'comment_12_content\').spin()'))
    comment_edit_save_button
  end

  it "should update the element with a failure message if the AJAX fails" do
    expects(:submit_to_remote).with(anything, anything,
                                    has_entry(:failure,
                                              '$(\'comment_12_content\').update("<h3 class=\'failure\'>Save Failed</h3>")'))
    comment_edit_save_button
  end
end
