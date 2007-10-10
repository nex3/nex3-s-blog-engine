require 'application_helper.rb'

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_nex3_session_id'

  helper_method :post_path, :post_url, :current_user, :admin?, :proper?

  filter_parameter_logging :pass

  protected

  def self.title(title)
    before_filter { |c| c.send(:title, title) }
  end

  def title(title)
    # Tags are stripped from this in application.haml
    @page_title = title
  end

  def view
    if instance_variable_get("@#{instance_variable_name}")
      response.template.instance_variable_set("@#{instance_variable_name}", current_objects)
    elsif instance_variable_get("@#{instance_variable_name.singularize}")
      response.template.instance_variable_set("@#{instance_variable_name.singularize}", current_object)
    end

    response.template
  end

  def post_path_with_slug(post)
    "#{post_path_without_slug(post)}-#{post.slug}"
  end
  alias_method_chain :post_path, :slug

  def post_url_with_slug(post)
    "#{post_url_without_slug(post)}-#{post.slug}"
  end
  alias_method_chain :post_url, :slug

  def comments_path_with_slug(post)
    "#{post_path(post)}#comments"
  end
  alias_method_chain :comments_path, :slug

  # ====
  # Login Management
  # ====

  def params_with_ip_and_agent
    ps = params_without_ip_and_agent

    if ps[:user] 
      ps[:user][:ip]       = request.remote_ip              if ps[:user][:ip].nil?
      ps[:user][:agent]    = request.env['HTTP_USER_AGENT'] if ps[:user][:agent].nil?
      ps[:user][:referrer] = request.env['HTTP_REFERRER']   if ps[:user][:referrer].nil?
    end

    ps
  end
  alias_method_chain :params, :ip_and_agent

  def current_user=(user)
    session[:user_id] = user.id

    if cookies[:user_id].nil? || cookies[:user_id][:value] != user.id
      cookies[:user_id] = {:value => user.id.to_s, :expires => 1.week.from_now}
    end
  end

  def current_user
    @current_user ||= if session[:user_id]
                        self.current_user = User.find(session[:user_id])
                      elsif cookies[:user_id]
                        self.current_user = User.find(cookies[:user_id])
                      elsif params[:admin]
                        if params[:admin][:name] && params[:admin][:pass] &&
                            user = User.login(params[:admin][:name], params[:admin][:pass])
                          user
                        else
                          params[:admin][:pass] = nil
                          raise "Invalid username or password."
                        end
                      else
                        User.anon
                      end
  end

  def current_user_if_same(user)
    if [:name, :link, :email].all? { |attr| current_user.send(attr).to_s == user.send(attr).to_s }
      current_user
    else
      user
    end
  end

  def admin?
    current_user.admin?
  end

  def proper?
    current_user == current_object.user
  end

  def require_admin
    force_signin unless admin?
  end

  def require_proper_user
    force_signin unless admin? || proper?
  end

  def force_signin
    session[:intended] = request.request_uri
    redirect_to :controller => 'signin', :action => 'new'
    false
  end
end
