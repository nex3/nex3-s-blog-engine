require File.dirname(__FILE__) + '/../spec_helper'

describe User, ".login with a correct password" do
  fixtures :users

  it "should return the user" do
    User.login('Admy', 'password').should == users(:admin)
  end
end

describe User, ".login with an incorrect password" do
  fixtures :users

  it "should return nil" do
    User.login('Admy', 'notpassword').should be_nil
  end
end

describe User, ".login with a non-admin" do
  fixtures :users

  it "should return nil" do
    User.login('Jenny', 'password').should be_nil
  end
end

describe User, ".login with a nonexistant username" do
  fixtures :users

  it "should return nil" do
    User.login('Not A User', 'password').should be_nil
  end
end

describe User, ".admins" do
  fixtures :users

  it "should return all admin users" do
    admins = User.admins
    admins.should include(users(:admin))
    admins.should include(users(:otheradmin))
  end
end

describe User, ".anon" do
  fixtures :users

  it "should return a user with name 'Anonymous'" do
    User.anon.name.should == "Anonymous"
  end

  it "should return a user without admin privileges" do
    User.anon.should_not be_admin
  end

  it "should return a user without an id" do
    User.anon.id.should be_nil
  end
end

describe User, ".all_sorted_by_count" do
  fixtures :users

  it "should return all posts" do
    User.all_sorted_by_count.should have(User.count).users
  end

  it "should order by comment count, with the highest count first" do
    user_counts = User.all_sorted_by_count.map { |u| u.comment_count }
    user_counts.should == user_counts.sort.reverse
  end
end

describe User, "found with all_sorted_by_count" do
  fixtures :users

  it "should return the correct value for comment_count" do
    User.all_sorted_by_count[0].comment_count.should == 2
  end

  it "shouldn't use a database call to return comment_count" do
    User.expects(:count_by_sql).never
    User.all_sorted_by_count[0].comment_count
  end
end

describe User, "with a normal configuration" do
  fixtures :users

  it "should return the correct number of comments" do
    users(:jenny).comment_count.should == 2
  end

  it "should add http:// to a link without it for href" do
    users(:linked).href.should == "http://www.google.com"
  end

  it "shouldn't add http:// to links that already have it for href" do
    users(:httplinked).href.should == "http://www.google.com"
  end

  it "should be valid" do
    users(:jenny).should be_valid
  end
end

describe User, "without a name" do
  fixtures :users

  it "should have one error on name" do
    users(:nameless).should have(1).error_on(:name)
  end
end

describe User, "with a name longer than thirty characters" do
  fixtures :users

  it "should have one error on name" do
    users(:longname).should have(1).error_on(:name)
  end
end

describe User, "with two comments" do
  fixtures :users, :comments

  it "should have 2 comments" do
    users(:jenny).should have(2).comments
  end

  it "should have a comment_count of 2" do
    users(:jenny).comment_count.should == 2
  end

  it "should only calculate comment_count once" do
    User.expects(:count_by_sql).returns(2).once
    5.times { users(:jenny).comment_count }
  end
end

describe User, "with the same name as an admin" do
  fixtures :users

  it "should have one error on name" do
    User.new(:name => 'Admy').should have(1).error_on(:name)
  end
end

describe User, "with the same name as a non-admin" do
  fixtures :users

  it "should have one error on name" do
    User.new(:name => 'Jenny').should have(:no).errors_on(:name)
  end
end

describe User, "with admin privileges" do
  fixtures :users

  it "shouldn't be flagged as having a non-unique name" do
    users(:admin).should have(:no).errors_on(:name)
  end
end

[:password, :salt, :pass_hash, :link, :email].each do |attr|
  describe User, "with an empty #{attr}" do
    it "should save with a nil #{attr}" do
      user = User.new(:name => "Foo", attr => "")
      user.save
      user.send(attr).should be_nil
    end
  end
end

describe User, "with a properly confirmed password" do
  before :each do
    @user = User.new(:name => "Foo", :password => "password",
                     :password_confirm => "password")
  end

  it "should save successfully" do
    @user.save.should be_true
  end

  it "should be accessible via User.login after saving" do
    @user.save
    User.login("Foo", "password").should == @user
  end
end

describe User, "with an unconfirmed password" do
  before :each do
    @user = User.new(:name => "Foo", :password => "password",
                     :password_confirm => "notpassword")
  end

  it "shouldn't save successfully" do
    @user.save.should be_false
  end

  it "should have one error on password" do
    @user.save

    # have(:no).errors_on(:password) doesn't work
    # because password validation isn't actually
    # a validation step
    @user.errors.on(:password).should_not be_nil
  end
end
