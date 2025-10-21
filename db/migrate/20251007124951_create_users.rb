class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :auth_token
      t.integer :role
      t.boolean :active

      t.timestamps
    end

    add_index :users, :auth_token, unique: truel
  end
end
