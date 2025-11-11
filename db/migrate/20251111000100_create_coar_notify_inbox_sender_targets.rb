class CreateCoarNotifyInboxSenderTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_sender_targets do |t|
      t.references :sender, null: false, foreign_key: { to_table: :coar_notify_inbox_senders }
      t.references :target, null: false, foreign_key: { to_table: :coar_notify_inbox_targets }

      t.timestamps
    end

    add_index :coar_notify_inbox_sender_targets, [:sender_id, :target_id], unique: true
  end
end
