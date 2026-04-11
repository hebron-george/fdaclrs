class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user,   null: false, foreign_key: true
      t.string     :name,   null: false
      t.jsonb      :filters, null: false, default: {}
      t.boolean    :active,  null: false, default: true
      t.string     :unsubscribe_token, null: false

      t.timestamps
    end

    add_index :subscriptions, :unsubscribe_token, unique: true
    add_index :subscriptions, [:user_id, :active]
  end
end
