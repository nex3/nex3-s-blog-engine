ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'signin' do |s|
    s.signin 'signin', :action => 'new', :conditions => {:method => :get}
    s.connect 'signin', :action => 'create', :conditions => {:method => :post}
    s.signout 'signin', :action => 'destroy', :conditions => {:method => :delete}
  end

  map.resources :users

  map.connect "posts/new.:format", :controller => 'posts', :action => 'new', :conditions => {:method => :post}
  map.dates "posts/dates/:year/:month", :controller => 'posts', :action => 'dates', :conditions => {:method => :get}, :defaults => {:month => nil, :year => nil}
  map.resources :posts do |p|
    p.connect "posts/:post_id/comments/new.:format", :controller => 'comments', :action => 'new', :conditions => {:method => :post}
    p.resources :comments
  end

  map.resources :comments, :name_prefix => "all_"

  map.connect '', :controller => 'posts'

  map.connect ':page', :controller => 'static', :action => 'show', :conditions => {:method => :get}
end
