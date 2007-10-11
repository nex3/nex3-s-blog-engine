class CommentsController < ApplicationController
  make_resourceful do
    actions :new, :destroy, :update, :edit, :create

    belongs_to :post

    before(:create) do
      @comment.spam! if params[:email] && !params[:email].empty?
      @user = current_user_if_same User.new(params[:user])
      @comment.user = @user
    end

    before(:destroy) do
      @comment.spam! if params[:spam]
    end

    before(:new) { @comment.user ||= current_user_if_same User.new(params[:user]) }

    response_for(:create) do
      self.current_user = @user
      redirect_to post_path(@post) + "#comment_#{@comment.id}"
    end

    response_for(:create_fails) do
      flash[:comment_errors] = view.error_messages_for('comment')
      redirect_to :back
    end
  end

  layout false, :only => :edit

  before_filter :require_proper_user, :only => [:update, :edit, :destroy]
  before_filter :ensure_post_exists, :except => :index

  def show
    redirect_to "#{post_path(Post.find(params[:post_id]))}#comment_#{params[:id]}"
  end

  def index
    respond_to do |format|
      format.html do
        if params[:post_id]
          redirect_to post_path(@post) + '#comments'
        else
          redirect_to '/'
        end
      end
      format.atom do
        load_objects
        headers['Content-Type'] = 'application/atom+xml; charset=utf-8'
        render :action => 'index', :layout => false
      end
    end
  end

  def current_objects
    current_model.find(:all, :order => 'created_at DESC', :limit => 10, :include => :user)
  end

  def parents
    params[:post_id] ? super : []
  end

  def namespaces
    params[:post_id] ? [] : [:all]
  end

  def ensure_post_exists
    unless params[:post_id]
      redirect_to '/'
      false
    end
  end
end
