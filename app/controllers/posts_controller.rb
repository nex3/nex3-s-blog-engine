class PostsController < ApplicationController
  make_resourceful do
    actions :all

    before(:show) { title @post.title                  }
    before(:new)  { title 'New Post'                   }
    before(:edit) { title "Editing \"#{@post.title}\"" }

    before :index do
      if params[:query]
        title "Search results for \"#{CGI::escapeHTML params[:query]}\""
      end
    end

    response_for :new do |format|
      format.html { render :action => 'edit' }
      format.js
    end

    response_for :index do |format|
      format.html
      format.js { render :template => 'posts/index.rjs' }
      format.rss do
        headers['Content-Type'] = 'application/rss+xml; charset=utf-8'
        render :action => 'index_rss', :layout => false
      end

      format.atom do
        headers['Content-Type'] = 'application/atom+xml; charset=utf-8'
        render :action => 'index_atom', :layout => false
      end
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

      parts = [view.silk_tag("book_#{prev ? 'previous' : 'next'}", :alt => prev ? 'Previous' : 'Next'), date.strftime(format)]
      parts.reverse! unless prev
      view.link_to parts.join, url
    else nil end
  end

  def current_object
    @current_object ||= Post.find(params[:id].scan(/^(\d+)/)[0][0].to_i,
                                  :include => :comments)
  end

  def current_objects
    @current_objects ||=
      if params[:query]
        term = "%#{params[:query]}%"
        Post.find(:all, :order => 'posts.created_at DESC', :include => :comments,
                  :conditions => ['content LIKE ? OR title LIKE ?', term, term])
      else
        Post.find(:all, :order => 'posts.created_at DESC',
                  :limit => 6, :include => :comments)
      end
  end
end
