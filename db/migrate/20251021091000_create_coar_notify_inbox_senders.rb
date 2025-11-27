class CreateCoarNotifyInboxSenders < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_senders do |t|
      t.references :user, null: false, foreign_key: { to_table: :coar_notify_inbox_users }
      t.references :origin, foreign_key: { to_table: :coar_notify_inbox_origins }
      t.boolean :active, default: false
      t.timestamps
    end
  end
end
