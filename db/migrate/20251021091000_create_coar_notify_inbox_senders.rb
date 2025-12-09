# frozen_string_literal: true

class CreateCoarNotifyInboxSenders < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_senders do |t|
      # username references coar_notify_inbox_users.username (we'll add FK below)
      t.string  :username,    null: false

      # store origin URI directly
      t.string  :origin_uri,  null: false

      # JSON column for sqlite (Rails maps to TEXT for sqlite). Default to empty array.
      # Note: Rails 7+ supports t.json on sqlite but it becomes TEXT; we will serialize in model.
      t.json    :target_uris, null: false, default: []

      t.boolean :active,      default: false, null: false

      t.timestamps
    end

    # Unique constraint: (username, origin_uri)
    add_index :coar_notify_inbox_senders,
              [:username, :origin_uri],
              unique: true,
              name: "index_coar_notify_inbox_senders_on_username_and_origin_uri"

    # Add foreign key from senders.username -> users.username
    # Note: This requires coar_notify_inbox_users.username be unique (you confirmed it is).
    add_foreign_key :coar_notify_inbox_senders,
                    :coar_notify_inbox_users,
                    column: :username,
                    primary_key: :username,
                    name: "fk_senders_username_to_users_username"
  end
end
