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
  create_table "coar_notify_inbox_consumers", force: :cascade do |t|
    t.string "username", null: false
    t.string "target_uri", null: false
    t.json "origin_uris", default: [], null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username", "target_uri"], name: "index_coar_notify_inbox_consumers_on_username_and_target_uri", unique: true
  end

  create_table "coar_notify_inbox_notification_types", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "notification_ids"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_coar_notify_inbox_notification_types_on_name", unique: true
  end

  create_table "coar_notify_inbox_notifications", force: :cascade do |t|
    t.string "username", null: false
    t.text "origin_uri", null: false
    t.text "target_uri", null: false
    t.text "raw_payload", null: false
    t.integer "notification_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_type_id"], name: "index_coar_notify_inbox_notifications_on_notification_type_id"
    t.index ["origin_uri"], name: "index_coar_notify_inbox_notifications_on_origin_uri"
    t.index ["target_uri"], name: "index_coar_notify_inbox_notifications_on_target_uri"
    t.index ["username"], name: "index_coar_notify_inbox_notifications_on_username"
  end

  create_table "coar_notify_inbox_origins", force: :cascade do |t|
    t.string "uri", null: false
    t.json "senders", default: [], null: false
    t.json "consumers", default: [], null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_coar_notify_inbox_origins_on_uri", unique: true
  end

  create_table "coar_notify_inbox_senders", force: :cascade do |t|
    t.string "username", null: false
    t.string "origin_uri", null: false
    t.json "target_uris", default: [], null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username", "origin_uri"], name: "index_coar_notify_inbox_senders_on_username_and_origin_uri", unique: true
  end

  create_table "coar_notify_inbox_targets", force: :cascade do |t|
    t.string "uri", null: false
    t.json "senders", default: [], null: false
    t.json "consumers", default: [], null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uri"], name: "index_coar_notify_inbox_targets_on_uri", unique: true
  end

  create_table "coar_notify_inbox_users", force: :cascade do |t|
    t.string "username", null: false
    t.string "name"
    t.string "auth_token"
    t.integer "role", default: 0, null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_coar_notify_inbox_users_on_auth_token", unique: true
    t.index ["username"], name: "index_coar_notify_inbox_users_on_username", unique: true
  end

  add_foreign_key "coar_notify_inbox_consumers", "coar_notify_inbox_users", column: "username", primary_key: "username"
  add_foreign_key "coar_notify_inbox_notifications", "coar_notify_inbox_notification_types", column: "notification_type_id"
  add_foreign_key "coar_notify_inbox_senders", "coar_notify_inbox_users", column: "username", primary_key: "username"
end
