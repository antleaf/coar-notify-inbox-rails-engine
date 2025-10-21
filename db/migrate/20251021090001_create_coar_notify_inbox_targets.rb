class CreateCoarNotifyInboxTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_targets do |t|
      t.string :uri, null: false

      t.timestamps
    end

    add_index :coar_notify_inbox_targets, :uri, unique: true
  end
end
