class RestfulFormWrapper
  def initialize(template, form_builder)
    @template = template
    @form_builder = form_builder
  end

  def method_missing(method, field, options = {})
    @template.open 'div', :class => field.to_s, :id => "#{field}_field" do
      @template.open('label', options[:label] || field.to_s.titleize,
           :for => "#{@template.instance_variable_name.singularize}_#{field}")
      @template.puts @template.find_and_preserve(@form_builder.send(method, field))
    end
  end
end

module ApplicationHelper

  # Generally useful tools

  def restful_form
    options = {
      :url  => params[:action] == 'new' ? objects_path : object_path,
      :html => params[:action] == 'new' ? {}           : {:method => :put}
    }

    form_for(instance_variable_name.singularize, options) do |f|
      yield(RestfulFormWrapper.new(self, f)) if block_given?
    end
  end

  def absolute_anchors(text, url)
    text.gsub(/href=(["'])#/) { "href=#{$1}#{url}#" }
  end

  def preview_button(path, element)
    submit_to_remote 'submit', 'Preview', :url => path + '.js',
      :html => {:class => 'button'}, :method => :post,
      :loading => "$(#{element.to_json}).spin()",
      :failure => "$(#{element.to_json}).update(#{failure_html('Preview Failed').to_json})"
  end

  def failure_html(text)
    capture_haml do
      open(:div, :class => 'flash') { open(:div, :class => 'error') { open :h2, text } }
    end
  end

  def xml_stylesheet(name)
    "<?xml-stylesheet href=\"http://#{Nex3::Config['blog']['site']}#{stylesheet_path name}\" type=\"text/css\" ?>"
  end

  # Stuff for the application-wide layout

  def flash_display
    open 'div', flash[:error], :class => 'error' if flash[:error]
    open('h2') { open 'div', flash[:notice], :class => 'notice' } if flash[:notice]
  end

  def sidebar_admin_links
    [
     ['New Post', new_post_url],
     ['Manage Users', users_url],
     ['Sign Out', signout_url, {:method => :delete}]
    ]
  end

  def sidebar_links
    [
     ['About Me', {:controller => 'static', :action => 'show', :page => 'about'}],
     ['Feed', posts_path + '.atom'],
    ] + (admin? ? sidebar_admin_links : [['Sign In', signin_path]])
  end
end
