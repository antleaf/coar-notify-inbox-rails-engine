class CreateCoarNotifyInboxNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_notifications do |t|
      t.references :user, null: false, foreign_key: { to_table: :coar_notify_inbox_users }
      t.references :notification_type, null: false, foreign_key: { to_table: :coar_notify_inbox_notification_types }
      t.references :origin, null: false, foreign_key: { to_table: :coar_notify_inbox_origins }
      t.references :target, null: false, foreign_key: { to_table: :coar_notify_inbox_targets }
      if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
         t.jsonb :payload, default: {}
      else
        t.json :payload, default: {}
      end
      t.timestamps
    end
  end
end
