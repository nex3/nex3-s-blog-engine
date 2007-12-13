ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'signin' do |s|
    s.signin 'signin', :action => 'new', :conditions => {:method => :get}
    s.connect 'signin', :action => 'create', :conditions => {:method => :post}
    s.signout 'signin', :action => 'destroy', :conditions => {:method => :delete}
  end

  map.resources :users

  map.dates "posts/dates/:year/:month", :controller => 'posts', :action => 'dates', :conditions => {:method => :get}, :defaults => {:month => nil, :year => nil}
  map.resources :posts,    :new => { :new => :post } do |p|
    p.resources :comments, :new => { :new => :post }
  end
  map.resources :comments

  map.connect ':page', :controller => 'static', :action => 'show', :conditions => {:method => :get}

  map.root :controller => 'posts'
end
