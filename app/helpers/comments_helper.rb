module CommentsHelper
  def comment_edit_save_button
    submit_to_remote 'submit', 'Save', :url => object_path + '.js',
      :html => {:class => 'button'}, :method => :put,
      :submit => "comment_#{@comment.id}_content_field",
      :loading => "$('comment_#{@comment.id}_content').spin()",
      :failure => "$('comment_#{@comment.id}_content').update(\"<h3 class='failure'>Save Failed</h3>\")"
  end

  def atom_title(comment)
    h((params[:post_id] ? '' : "#{comment.post.title} : ") +
      truncate(comment.content.gsub(/\s+/, ' '), 50))
  end
end
