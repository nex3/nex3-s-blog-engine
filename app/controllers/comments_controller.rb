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
      redirect_to "#{parent_path}#comment_#{@comment.id}"
    end

    response_for(:create_fails) do
      flash[:comment_errors] = view.error_messages_for('comment')
      redirect_to :back
    end
  end

  layout false, :only => :edit

  before_filter :require_proper_user, :only => [:update, :edit, :destroy]
  before_filter :ensure_parent_exists, :only => :create

  def show
    redirect_to "#{post_path(current_object.post)}#comment_#{params[:id]}"
  end

  def index
    respond_to do |format|
      format.html do
        redirect_to "#{parent_path}#comments" if ensure_parent_exists
      end
      format.atom do
        load_objects
        headers['Content-Type'] = 'application/atom+xml; charset=utf-8'
        render :action => 'index', :layout => false
      end
    end
  end

  def current_objects
    current_model.find(:all, :order => 'comments.created_at DESC', :limit => 10,
                       :include => parent? ? :user : [:user, :post])
  end
end
