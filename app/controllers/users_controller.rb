class UsersController < ApplicationController
  make_resourceful do
    build :index, :edit, :update, :create, :destroy

    response_for(:update) { redirect_to objects_path }
  end

  before_filter :require_admin

  title 'Manage Users'

  def current_objects
    @current_objects ||= User.all_sorted_by_count
  end
end
