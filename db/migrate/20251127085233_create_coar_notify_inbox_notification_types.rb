# frozen_string_literal: true

class CreateCoarNotifyInboxNotificationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_notification_types do |t|
      t.string  :name, null: false
      t.text    :description

      # JSON array of notification IDs
      # SQLite stores JSON as TEXT
      t.text    :notification_ids

      # For optimistic locking during concurrent updates
      t.integer :lock_version, default: 0, null: false

      t.timestamps
    end

    add_index :coar_notify_inbox_notification_types, :name, unique: true
  end
end
