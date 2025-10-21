class CreateCoarNotifyInboxConsumers < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_consumers do |t|
      t.references :user, null: false

      t.timestamps
    end

    add_index :coar_notify_inbox_consumers, :name
  end
end
