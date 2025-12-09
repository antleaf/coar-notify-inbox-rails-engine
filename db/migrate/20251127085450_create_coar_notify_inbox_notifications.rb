# frozen_string_literal: true

class CreateCoarNotifyInboxNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_notifications do |t|
      # Owner username (consumer owner's username)
      t.string :username, null: false

      # Matched inbox URIs
      t.string :origin_uri, null: false
      t.string :target_uri, null: false

      # Raw COAR Notify payload (json)
      t.json :payload, null: false

      # FK to notification_type (added later by other migration, or we can add now as big_int)
      t.bigint :notification_type_id

      t.timestamps
    end

    add_index :coar_notify_inbox_notifications, :username
    add_index :coar_notify_inbox_notifications, :origin_uri
    add_index :coar_notify_inbox_notifications, :target_uri
    add_index :coar_notify_inbox_notifications, :notification_type_id
  end
end
