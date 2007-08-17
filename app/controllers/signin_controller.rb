class SigninController < ApplicationController
  def new; end

  def create
    user = User.login(params[:name], params[:pass])
    if user.nil?
      flash[:error] = 'Name or password invalid.'
      redirect_to :action => 'new'
    else
      self.current_user = user
      flash[:notice] = "Successfully signed in."
      redirect_to session[:intended] || '/'
      session[:intended] = nil
    end
  end

  def destroy
    session[:user_id] = nil
    cookies[:user_id] = nil
    flash[:notice] = "Successfully signed out."
    redirect_to '/'
  end
end
