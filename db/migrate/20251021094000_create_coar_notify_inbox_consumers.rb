# frozen_string_literal: true

class CreateCoarNotifyInboxConsumers < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_consumers do |t|
      # owner username (references users.username)
      t.string :username, null: false

      # target URI stored directly
      t.string :target_uri, null: false

      # list of origin URIs (json). On sqlite this becomes TEXT; we'll use attribute :json in model.
      t.json   :origin_uris, null: false, default: []

      t.boolean :active, default: false, null: false

      t.timestamps
    end

    # Unique constraint: username + target_uri
    add_index :coar_notify_inbox_consumers,
              [:username, :target_uri],
              unique: true,
              name: "index_coar_notify_inbox_consumers_on_username_and_target_uri"

    # Foreign key from consumers.username -> users.username
    # Requires that coar_notify_inbox_users.username is unique (you have that).
    add_foreign_key :coar_notify_inbox_consumers,
                    :coar_notify_inbox_users,
                    column: :username,
                    primary_key: :username,
                    name: "fk_consumers_username_to_users_username"
  end
end
