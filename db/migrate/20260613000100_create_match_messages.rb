class CreateMatchMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :match_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :match_messages, :created_at
  end
end
