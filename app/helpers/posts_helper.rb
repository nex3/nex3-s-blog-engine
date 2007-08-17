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
    h absolute_anchors(post.render.gsub(/<img src=("|')\//,
                                        "<img src=\\1#{feed[:url]}/"),
                       post_url(post))
  end

  def date_links
    if @prev_link || @next_link
      open 'div', :class => 'date_links' do
        open 'div', @prev_link, :class => 'prev' if @prev_link
        open 'div', @next_link, :class => 'next' if @next_link
      end
    end
  end

  def delete_comment_link
    link_to(silk_tag('comment_delete', :alt => 'Delete comment'),
            comment_path(@post, @comment),
            :method => :delete, :confirm => 'Really delete comment?', :title => 'Delete comment')
  end

  def edit_comment_link
    link_to_remote(silk_tag('comment_edit', :alt => 'Edit comment'),
                   :url => edit_comment_path(@comment.post, @comment),
                   :update => "comment_#{@comment.id}_content", :method => :get, :title => 'Edit comment')
  end

  # Feed helpers

  @@feed_info = {
    :title => 'Blog Posts : Nex3',
    :url => 'http://nex3.leeweiz.net',
    :desc => 'Nathan Weizenbaum\'s blog, all about things that interest him.',
    :lang => 'en-us',
    :name => 'Nathan Weizenbaum',
    :email => 'nex342@gmail.com',
    :ttl => 1440,
#    :image => ?
  }

  def self.feed
    @@feed_info
  end

  def feed
    @@feed_info
  end
end
