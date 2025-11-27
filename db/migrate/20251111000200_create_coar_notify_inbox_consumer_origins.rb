class CreateCoarNotifyInboxConsumerOrigins < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_consumer_origins do |t|
      t.references :consumer, null: false, foreign_key: { to_table: :coar_notify_inbox_consumers }
      t.references :origin, null: false, foreign_key: { to_table: :coar_notify_inbox_origins }

      t.timestamps
    end

    add_index :coar_notify_inbox_consumer_origins, [:consumer_id, :origin_id], unique: true
  end
end
