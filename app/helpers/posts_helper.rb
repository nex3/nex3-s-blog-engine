module PostsHelper
  def prev_link_text
    silk_tag('arrow_left', :alt => 'Previous Post') + ' ' +
      h(@post.prev.title)
  end

  def next_link_text
    h(@post.next.title) + ' ' +
      silk_tag('arrow_right', :alt => 'Next Post')
  end

  def delete_link
    link_to silk_tag('page_white_delete', :alt => 'Delete post.'),
      post_path(@post), :method => :delete, :confirm => "Really delete #{@post.title}?",
      :title => 'Delete post'
  end

  def edit_link
    link_to silk_tag('page_white_edit', :alt => 'Edit post.'),
      edit_post_path(@post), :title => 'Edit post'
  end

  def post_content(post)
    absolute_anchors(find_and_preserve(post.render).gsub(/<img src=("|')\//,
                                                         "<img src=\\1#{feed[:url]}"),
                     post_path(post))
  end

  def date_links
    if @prev_link || @next_link
      open 'div', :class => 'date_links' do
        open 'div', @prev_link, :class => 'prev' if @prev_link
        open 'div', @next_link, :class => 'next' if @next_link
      end
    end
  end

  def spam_comment_link
    link_to(silk_tag('cross', :alt => 'Mark as spam'),
            post_comment_path(@post, @comment) + '?spam=1',
            :method => :delete, :confirm => 'Mark comment as spam and delete it?', :title => 'Mark as spam')
  end

  def delete_comment_link
    link_to(silk_tag('comment_delete', :alt => 'Delete comment'),
            post_comment_path(@post, @comment),
            :method => :delete, :confirm => 'Delete comment?', :title => 'Delete comment')
  end

  def edit_comment_link
    link_to_remote(silk_tag('comment_edit', :alt => 'Edit comment'),
                   { :url => edit_post_comment_path(@post || @comment.post, @comment) + '.html',
                     :update => "comment_#{@comment.id}_content", :method => :get},
                   :title => 'Edit comment')
  end

  # Feed helpers

  @@feed_info = {
    :url => "http://#{Nex3::Config['blog']['site']}/",
    :desc => "#{Nex3::Config['author']['name']}'s blog, all about things that interest him.",
    :name => Nex3::Config['author']['name'],
    :email => Nex3::Config['author']['email'],
    :ttl => 1440,
  }

  def self.feed
    @@feed_info
  end

  def feed
    @@feed_info
  end
end
