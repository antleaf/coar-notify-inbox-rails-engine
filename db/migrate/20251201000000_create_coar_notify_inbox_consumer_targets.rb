class CreateCoarNotifyInboxConsumerTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_consumer_targets do |t|
      t.references :consumer, null: false, foreign_key: { to_table: :coar_notify_inbox_consumers }
      t.references :target, null: false, foreign_key: { to_table: :coar_notify_inbox_targets }

      t.timestamps
    end

    add_index :coar_notify_inbox_consumer_targets, [:consumer_id, :target_id], unique: true
  end
end
