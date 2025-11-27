class CreateCoarNotifyInboxConsumers < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_consumers do |t|
      t.references :user, null: false, foreign_key: { to_table: :coar_notify_inbox_users }
      t.references :target, foreign_key: { to_table: :coar_notify_inbox_targets }
      t.boolean :active, default: false
      t.timestamps
    end
  end
end
