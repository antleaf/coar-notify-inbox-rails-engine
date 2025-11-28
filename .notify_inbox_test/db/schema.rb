# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_27_085450) do
  create_table "coar_notify_inbox_consumer_origins", force: :cascade do |t|
    t.integer "consumer_id", null: false
    t.integer "origin_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consumer_id", "origin_id"], name: "idx_on_consumer_id_origin_id_51018369ec", unique: true
    t.index ["consumer_id"], name: "index_coar_notify_inbox_consumer_origins_on_consumer_id"
    t.index ["origin_id"], name: "index_coar_notify_inbox_consumer_origins_on_origin_id"
  end

  create_table "coar_notify_inbox_consumers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "target_id"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_id"], name: "index_coar_notify_inbox_consumers_on_target_id"
    t.index ["user_id"], name: "index_coar_notify_inbox_consumers_on_user_id"
  end

  create_table "coar_notify_inbox_notification_types", force: :cascade do |t|
    t.string "notification_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "coar_notify_inbox_notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "notification_type_id", null: false
    t.integer "origin_id", null: false
    t.integer "target_id", null: false
    t.json "payload", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_type_id"], name: "index_coar_notify_inbox_notifications_on_notification_type_id"
    t.index ["origin_id"], name: "index_coar_notify_inbox_notifications_on_origin_id"
    t.index ["target_id"], name: "index_coar_notify_inbox_notifications_on_target_id"
    t.index ["user_id"], name: "index_coar_notify_inbox_notifications_on_user_id"
  end

  create_table "coar_notify_inbox_origins", force: :cascade do |t|
    t.string "uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_coar_notify_inbox_origins_on_uri", unique: true
  end

  create_table "coar_notify_inbox_sender_targets", force: :cascade do |t|
    t.integer "sender_id", null: false
    t.integer "target_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sender_id", "target_id"], name: "idx_on_sender_id_target_id_862d019f1e", unique: true
    t.index ["sender_id"], name: "index_coar_notify_inbox_sender_targets_on_sender_id"
    t.index ["target_id"], name: "index_coar_notify_inbox_sender_targets_on_target_id"
  end

  create_table "coar_notify_inbox_senders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "origin_id"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["origin_id"], name: "index_coar_notify_inbox_senders_on_origin_id"
    t.index ["user_id"], name: "index_coar_notify_inbox_senders_on_user_id"
  end

  create_table "coar_notify_inbox_targets", force: :cascade do |t|
    t.string "uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_coar_notify_inbox_targets_on_uri", unique: true
  end

  create_table "coar_notify_inbox_users", force: :cascade do |t|
    t.string "username", null: false
    t.string "name"
    t.string "auth_token"
    t.integer "role"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_coar_notify_inbox_users_on_auth_token", unique: true
  end

  add_foreign_key "coar_notify_inbox_consumer_origins", "coar_notify_inbox_consumers", column: "consumer_id"
  add_foreign_key "coar_notify_inbox_consumer_origins", "coar_notify_inbox_origins", column: "origin_id"
  add_foreign_key "coar_notify_inbox_consumers", "coar_notify_inbox_targets", column: "target_id"
  add_foreign_key "coar_notify_inbox_consumers", "coar_notify_inbox_users", column: "user_id"
  add_foreign_key "coar_notify_inbox_notifications", "coar_notify_inbox_notification_types", column: "notification_type_id"
  add_foreign_key "coar_notify_inbox_notifications", "coar_notify_inbox_origins", column: "origin_id"
  add_foreign_key "coar_notify_inbox_notifications", "coar_notify_inbox_targets", column: "target_id"
  add_foreign_key "coar_notify_inbox_notifications", "coar_notify_inbox_users", column: "user_id"
  add_foreign_key "coar_notify_inbox_sender_targets", "coar_notify_inbox_senders", column: "sender_id"
  add_foreign_key "coar_notify_inbox_sender_targets", "coar_notify_inbox_targets", column: "target_id"
  add_foreign_key "coar_notify_inbox_senders", "coar_notify_inbox_origins", column: "origin_id"
  add_foreign_key "coar_notify_inbox_senders", "coar_notify_inbox_users", column: "user_id"
end
