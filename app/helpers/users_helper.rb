module UsersHelper
  def edit_link
    link_to silk_tag('user_edit', :alt => 'Edit user info'),
      edit_user_path(@user), :title => 'Edit user info'
  end

  def delete_link
    link_to silk_tag('user_delete', :alt => 'Delete user'),
      user_path(@user), :method => :delete, :confirm => "Really delete #{h @user.name}?",
      :title => 'Delete user'
  end
end
