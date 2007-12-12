# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 5) do

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "post_id"
    t.text     "content",    :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", :force => true do |t|
    t.string   "title",      :default => "", :null => false
    t.text     "content",    :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts_tags", :id => false, :force => true do |t|
    t.integer "post_id"
    t.integer "tag_id"
  end

  add_index "posts_tags", ["post_id"], :name => "index_posts_tags_on_post_id"
  add_index "posts_tags", ["tag_id"], :name => "index_posts_tags_on_tag_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tags", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  create_table "users", :force => true do |t|
    t.string  "name",      :default => "",    :null => false
    t.boolean "admin",     :default => false
    t.string  "email"
    t.string  "link"
    t.string  "pass_hash"
    t.string  "salt"
    t.string  "ip"
    t.string  "agent"
    t.string  "referrer"
  end

end
