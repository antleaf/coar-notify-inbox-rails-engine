# frozen_string_literal: true

class CreateCoarNotifyInboxTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_targets do |t|
      t.string :uri, null: false
      t.json   :senders, default: [], null: false
      t.json   :consumers, default: [], null: false

      # optimistic locking
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :coar_notify_inbox_targets, :uri, unique: true, name: "index_coar_notify_inbox_targets_on_uri"
  end
end
