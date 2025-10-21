class CreateCoarNotifyInboxSenderTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_owner_targets do |t|
      t.references :owner, polymorphic: true, null: false
      t.references :target, null: false, foreign_key: { to_table: :coar_notify_inbox_targets }

      t.timestamps
    end

    # Ensure unique index on owner and target
    unless index_name_exists?(:coar_notify_inbox_owner_targets, 'index_owner_targets_on_owner_and_target')
      add_index :coar_notify_inbox_owner_targets, [:owner_type, :owner_id, :target_id], unique: true, name: 'index_owner_targets_on_owner_and_target'
    end
  end
end
