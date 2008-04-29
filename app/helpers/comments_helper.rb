module CommentsHelper
  def comment_edit_save_button
    submit_to_remote 'submit', 'Save', :url => object_path + '.js',
      :html => {:class => 'button'}, :method => :put,
      :submit => "comment_#{@comment.id}_content_field",
      :loading => "$('comment_#{@comment.id}_content').spin()",
      :failure => "$('comment_#{@comment.id}_content').update(#{failure_html('Save Failed').to_json})"
  end

  def comment_edit_cancel_action
    remote_function :url => object_path + '.js', :method => :get,
      :loading => "$('comment_#{@comment.id}_content').spin()",
      :failure => "$('comment_#{@comment.id}_content').update(#{failure_html('Failed').to_json})"
  end

  def atom_title(comment)
    h((params[:post_id] ? '' : "#{comment.post.title} : ") +
      truncate(comment.content.gsub(/\s+/, ' '), 50))
  end
end
