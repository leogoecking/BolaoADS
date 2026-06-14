class CreateActivityEventComments < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_event_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :activity_event, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :activity_event_comments, :created_at
  end
end
