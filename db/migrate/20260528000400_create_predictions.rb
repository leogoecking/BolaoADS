class CreatePredictions < ActiveRecord::Migration[8.0]
  def change
    create_table :predictions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.integer :home_score, null: false
      t.integer :away_score, null: false
      t.integer :points, null: false, default: 0
      t.datetime :calculated_at

      t.timestamps
    end

    add_index :predictions, %i[user_id match_id], unique: true
    add_index :predictions, :points
  end
end
