require File.dirname(__FILE__) + '/../spec_helper'


describe PostsHelper, "#post_content" do
  before(:each) do
    @post = stub
    stubs(:post_url)
  end

  it "should make image tags absolute" do
    @post.stubs(:render).returns("<img src=\"/images/foo.png\"/>")
    expects(:absolute_anchors).with("<img src=\"http://nex3.leeweiz.net/images/foo.png\"/>",
                                    anything)
    post_content(@post)
  end

  it "should make image tags with single quote absolute" do
    @post.stubs(:render).returns("<img src='/images/foo.png'/>")
    expects(:absolute_anchors).with("<img src='http://nex3.leeweiz.net/images/foo.png'/>",
                     anything)
    post_content(@post)
  end
end
