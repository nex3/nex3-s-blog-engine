require File.dirname(__FILE__) + '/../spec_helper'


describe PostsHelper, "#post_content" do
  before(:each) do
    @post = stub
    stubs(:post_path)
    @post.stubs(:render)
  end

  it "should make image tags absolute" do
    stubs(:find_and_preserve).returns("<img src=\"/images/foo.png\"/>")
    expects(:absolute_anchors).with("<img src=\"http://nex3.leeweiz.net/images/foo.png\"/>",
                                    anything)
    post_content(@post)
  end

  it "should make image tags with single quote absolute" do
    stubs(:find_and_preserve).returns("<img src='/images/foo.png'/>")
    expects(:absolute_anchors).with("<img src='http://nex3.leeweiz.net/images/foo.png'/>",
                     anything)
    post_content(@post)
  end
end
