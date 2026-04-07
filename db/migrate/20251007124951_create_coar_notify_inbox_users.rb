# frozen_string_literal: true

class CreateCoarNotifyInboxUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_users do |t|
      # username is UNIQUE and used as FK by senders
      t.string :username, null: false

      t.string :name

      # Auth token used for identifying user; must be unique
      t.string :auth_token

      # Role (enum): 0 = user, 1 = admin
      t.integer :role, null: false, default: 0

      # Active flag
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    # Unique indexes
    add_index :coar_notify_inbox_users, :username, unique: true
    add_index :coar_notify_inbox_users, :auth_token, unique: true
  end
end
