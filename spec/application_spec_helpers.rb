module ApplicationSpecHelpers
  def publicize_helpers
    (kontroller.protected_instance_methods - Object.protected_instance_methods).each do |method|
      kontroller.send(:public, method)
    end
  end

  def set_admin
    @user = stub('@user')
    @user.stubs(:admin?).returns(true)
    controller.stubs(:current_user).returns(@user)
  end

  def set_proper
    @user = stub('@user')
    @user.stubs(:admin?).returns(false)
    controller.stubs(:current_user).returns(@user)
    controller.current_object.stubs(:user).returns(@user)
  end

  def kontroller
    @kontroller ||= class << controller; self; end
  end
end
