class PostsController < ApplicationController
  make_resourceful do
    actions :all

    before(:show) { title @post.title                  }
    before(:new)  { title 'New Post'                   }
    before(:edit) { title "Editing \"#{@post.title}\"" }

    before :index do
      if params[:query]
        title "Search results for \"#{CGI::escapeHTML params[:query]}\""
      elsif params[:tag]
        title "Posts about " + params[:tag].titleize
      end
    end

    response_for :new do |format|
      format.html { render :action => 'edit' }
      format.js
    end

    response_for :index do |format|
      format.html
      format.js { render :template => 'posts/index.rjs' }
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
    @current_object ||= Post.find(params[:id].scan(/^(\d+)/)[0][0].to_i)
  end

  def current_objects
    @current_objects ||=
      begin
        opts = {:order => 'posts.created_at DESC', :limit => 6, :include => [:comments, :tags]}

        if params[:tag]
          opts[:joins] = 'INNER JOIN posts_tags AS inner_posts_tags ON posts.id = inner_posts_tags.post_id'
          opts[:conditions] = ['inner_posts_tags.tag_id = ?',
                               Tag.find(:first, :conditions => {:name => params[:tag].downcase}).id]
        end

        if params[:query]
          term = "%#{params[:query]}%"
          cond = "posts.content LIKE ? OR posts.title LIKE ?"

          opts.delete :limit
          if opts[:conditions]
            opts[:conditions][0] << " AND (#{cond})"
            opts[:conditions] << term << term
          else
            opts[:conditions] = [cond, term, term]
          end
        end

        Post.find(:all, opts)
      end
  end
end
