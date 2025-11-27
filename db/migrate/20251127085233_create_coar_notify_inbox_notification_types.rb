class CreateCoarNotifyInboxNotificationTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :coar_notify_inbox_notification_types do |t|
      t.string :notification_type

      t.timestamps
    end
  end
end
