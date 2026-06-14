class CreateActivityEventReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_event_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :activity_event, null: false, foreign_key: true
      t.string :reaction_type, null: false

      t.timestamps
    end

    add_index :activity_event_reactions, :created_at
    add_index :activity_event_reactions, [ :user_id, :activity_event_id, :reaction_type ], unique: true
  end
end
