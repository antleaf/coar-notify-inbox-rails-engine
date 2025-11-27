class CreateCoarNotifyInboxNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :coar_notify_inbox_notifications do |t|
      t.references :user, null: false, foreign_key: { to_table: :coar_notify_inbox_users }
      t.references :notification_type, null: false, foreign_key: { to_table: :coar_notify_inbox_notification_types }
      t.references :origin, null: false, foreign_key: { to_table: :coar_notify_inbox_origins }
      t.references :target, null: false, foreign_key: { to_table: :coar_notify_inbox_targets }
      t.jsonb :payload, default: {}
      t.timestamps
    end
  end
end
