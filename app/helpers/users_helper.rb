module UsersHelper
  def delete_link
    link_to 'Delete', user_path(@user), :method => :delete, :confirm => "Really delete #{h @user.name}?"
  end
end
