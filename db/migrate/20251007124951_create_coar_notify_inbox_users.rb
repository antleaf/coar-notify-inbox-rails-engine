class CreateCoarNotifyInboxUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :coar_notify_inbox_users do |t|
      t.string :username, null: false
      t.string :name
      t.string :auth_token
      t.integer :role
      t.boolean :active

      t.timestamps
    end

    add_index :coar_notify_inbox_users, :auth_token, unique: true
  end
end
