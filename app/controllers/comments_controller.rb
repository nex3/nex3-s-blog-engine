class CommentsController < ApplicationController
  make_resourceful do
    actions :new, :destroy, :update, :edit, :create

    belongs_to :post

    before(:create) do
      @user = current_user_if_same User.new(params[:user])
      @comment.user = @user
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

  def index
    redirect_to post_url(Post.find(params[:post_id])) + '#comments'
  end
end
