class CreateCoarNotifyInboxSenders < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_senders do |t|
      t.references :user, null: false
      t.references :origin, foreign_key: { to_table: :coar_notify_inbox_origins }

      t.timestamps
    end

    add_index :coar_notify_inbox_senders, :origin_id
  end
end
