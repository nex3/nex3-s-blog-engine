module ResourcefulController
  def stub_index(models = 1)
    stub_generics
    
    stubs = [instance_variable_set("@#{controller.instance_variable_name}", stub)] * models
    controller.stubs(:current_objects).returns(stubs)
  end

  def stub_show
    stub_generics
    stub_instance
  end
  alias_method :stub_new,  :stub_show
  alias_method :stub_edit, :stub_show

  def stub_update
    stub_generics
    stub = stub_instance
    stub.stubs(:to_param).returns('1')
    stub.stubs(:update_attributes).returns(true)
  end

  def stub_create
    stub_generics
    stub = stub_instance
    stub.stubs(:to_param).returns('1')
    stub.stubs(:save).returns(true)
  end

  def stub_destroy
    stub_generics
    stub = stub_instance
    stub.stubs(:destroy).returns(true)
  end

  def stub_instance
    name = "@#{controller.instance_variable_name.singularize}"
    inst = stub(name)
    instance_variable_set(name, inst)
    controller.stubs(:current_object).returns(inst)

    mod = Module.new
    mod.send(:define_method, :build_object) { @current_object = inst }
    controller.extend mod

    inst
  end

  def stub_generics
    stub_parents
    stub_view
    stub_env
  end

  def stub_parents
    stubs = []
    (@parent_models || controller.parent_models).each do |parent|
      name = "@#{parent.to_s.underscore}"
      inst = stub(name)
      instance_variable_set(name, inst)
      stubs << inst
    end
    controller.stubs(:parent_objects).returns(stubs)
  end

  def stub_view
    @view = stub_everything('@view')
    controller.stubs(:view).returns(@view)
  end

  def stub_env
    request.env['HTTP_REFERER'] = 'http://back.host/'
  end
end
