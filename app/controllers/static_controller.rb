class StaticController < ApplicationController
  def show
    title params[:page].titleize
    render :partial => params[:page], :layout => true
  end
end
