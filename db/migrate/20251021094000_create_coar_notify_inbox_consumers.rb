class CreateCoarNotifyInboxConsumers < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_consumers do |t|
      t.references :coar_notify_inbox_user, null: false

      t.timestamps
    end
  end
end
