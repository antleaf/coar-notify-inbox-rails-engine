# frozen_string_literal: true

class CreateCoarNotifyInboxNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_notifications do |t|
      # Ownership (string-based, consistent with sender/consumer)
      t.string :username, null: false

      # Routing
      t.text :origin_uri, null: false
      t.text :target_uri, null: false

      # Raw COAR Notify JSON payload
      t.text :raw_payload, null: false

      # Notification type
      t.references :notification_type,
                   null: false,
                   foreign_key: { to_table: :coar_notify_inbox_notification_types }

      t.timestamps
    end

    add_index :coar_notify_inbox_notifications, :username
    add_index :coar_notify_inbox_notifications, :origin_uri
    add_index :coar_notify_inbox_notifications, :target_uri
  end
end
