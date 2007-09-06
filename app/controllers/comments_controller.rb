class CommentsController < ApplicationController
  make_resourceful do
    actions :new, :destroy, :update, :edit, :create

    belongs_to :post

    before(:create) do
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

  def show
    redirect_to "#{post_path(Post.find(params[:post_id]))}#comment_#{params[:id]}"
  end

  def index
    respond_to do |format|
      format.html { redirect_to post_path(Post.find(params[:post_id])) + '#comments' }
      format.atom do
        load_objects
        headers['Content-Type'] = 'application/atom+xml; charset=utf-8'
        render :action => 'index', :layout => false
      end
    end
  end

  def current_objects
    @post.comments.find(:all, :order => 'created_at DESC')
  end
end
