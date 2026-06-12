class CreateActivityFeed < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_events do |t|
      t.string :event_type, null: false
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.references :prediction, foreign_key: true
      t.string :message, null: false
      t.string :dedupe_key, null: false

      t.timestamps
    end

    create_table :prediction_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prediction, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :activity_events, :dedupe_key, unique: true
    add_index :activity_events, :created_at
    add_index :prediction_comments, :created_at
  end
end
