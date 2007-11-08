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

  def silk_tag(name, opts = {})
    image_tag("silk/#{name}.png", opts)
  end

  def absolute_anchors(text, url)
    text.gsub(/href=(["'])#/) { "href=#{$1}#{url}#" }
  end

  def preview_button(path, element)
    submit_to_remote 'submit', 'Preview', :url => path + '.js',
      :html => {:class => 'button'}, :method => :post,
      :loading => "$(#{element.to_json}).spin()",
      :failure => "$(#{element.to_json}).update(\"<h3 class='failure'>Preview Failed</h3>\")"
  end

  def xml_stylesheet(name)
    "<?xml-stylesheet href=\"http://nex-3.com#{stylesheet_path name}\" type=\"text/css\" ?>"
  end

  # Stuff for the application-wide layout

  def glyph
    '&#9731;'
  end

  def flash_display
    flash.each do |type, content|
      open 'div', content, :class => type.to_s
    end
  end

  def silk_link(title, url, icon, attrs = {})
    puts link_to(silk_tag(icon, :alt => title), url, attrs.merge(:title => title))
  end

  def sidebar_link(name, icon, url)
    puts link_to(silk_tag(icon, :alt => name) + name, url)
  end

  def sidebar_admin_links
    [
     ['New Post', new_post_url, 'page_white_add', {:class => 'new'}],
     ['Manage Users', users_url, 'group', {:class => 'users'}],
     ['Sign Out', signout_url, 'door_in', {:class => 'signout', :method => :delete}]
    ].each(&method(:silk_link))
  end

  def sidebar_links
    [
     ['About Me', 'user', {:controller => 'static', :action => 'show', :page => 'about'}],
     ['Feed', 'feed', posts_path + '.atom'],
    ].each(&method(:sidebar_link))
  end

  def bottom_links
    [
     ['Valid XHTML 1.1', 'http://validator.w3.org/check?uri=referer', 'xhtml'],
     ['Valid CSS', 'http://jigsaw.w3.org/css-validator/check/referer', 'css'],
     ['Legal Information',
      {:controller => 'static', :action => 'show', :page => 'legal'}, 'information']
    ].each(&method(:silk_link))
  end
end
