# frozen_string_literal: true

class CreateCoarNotifyInboxNotificationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_notification_types do |t|
      # canonical name of the type (e.g. "ReviewAction")
      t.string :name, null: false
      t.string :label
      t.text   :description

      # keep list of notification ids for this type (json array)
      t.json :notification_ids, null: false, default: []

      # optimistic locking to safely append notification ids concurrently
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :coar_notify_inbox_notification_types, :name, unique: true, name: "index_notification_types_on_name"
  end
end
