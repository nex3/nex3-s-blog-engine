class PostsController < ApplicationController
  make_resourceful do
    actions :all

    before(:show) { title @post.title                  }
    before(:new)  { title 'New Post'                   }
    before(:edit) { title "Editing \"#{@post.title}\"" }

    before :index do
      if params[:query]
        title "Search results for \"#{CGI::escapeHTML params[:query]}\""
      elsif tags
        title "Posts about " + tags.map(&:titleize).to_sentence
      end
    end

    response_for :new do |format|
      format.html { render :action => 'edit' }
      format.js
    end

    response_for :index do |format|
      format.html
      format.js
      format.atom
    end

    response_for(:create_fails, :update_fails) do
      flash[:error] = view.error_messages_for('post')
      @action_name = params[:action] = params[:action] == 'create' ? 'new' : 'edit'
      render :action => 'edit', :status => 422
    end
  end

  before_filter :require_admin, :only => [:new, :edit, :create, :update, :destroy]

  def dates
    if params[:year].nil?
      redirect_to :action => 'index'
      return
    end

    date = Date.civil(*([:year, :month, :day].map{|a| (params[a] || 1).to_i })).to_time
    next_date = date.send(params[:month] ? :next_month : :next_year)
    format = params[:month] ? '%B %Y' : '%Y'

    title date.strftime(format)

    @next_link = date_link(Post.after(next_date), format, false)
    @prev_link = date_link(Post.before(date), format, true)
    @posts = Post.between(date, next_date)
  end

  protected

  def date_link(post, format, prev)
    if post
      date = post.created_at
      url = url_for(:action => :dates, :year => date.year,
                    :month => params[:month] && date.month)

      link = date.strftime(format)
      view.link_to prev ? "&larr; #{link}" : "#{link} &rarr;", url
    else nil end
  end

  def current_object
    @current_object ||= Post.find(params[:id].scan(/^(\d+)/)[0][0])
  end

  def current_objects
    @current_objects ||=
      Post.find(:all, :order => 'posts.created_at DESC', :limit => params[:format] == 'js' ? nil : 6,
                :include => [:comments, :tags], :offset => page * 6, :tags => tags,
                :query => params.include?(:query) ? params[:query] || "" : nil)
  end

  def page
    (params[:page] || 0).to_i
  end
  helper_method :page

  def tags
    return if params[:tag].nil? && params[:tags].nil?
    @tags ||= "#{params[:tag]},#{params[:tags]}".split(',').map(&:downcase).map(&:strip).reject(&:empty?)
  end
  helper_method :tags
end
