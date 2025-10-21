class CreateCoarNotifyInboxOrigins < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_origins do |t|
      t.string :uri, null: false

      t.timestamps
    end

    add_index :coar_notify_inbox_origins, :uri, unique: true
  end
end
