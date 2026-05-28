class CreateSpecialPredictions < ActiveRecord::Migration[8.0]
  def change
    create_table :special_questions do |t|
      t.string :key, null: false
      t.string :prompt, null: false
      t.string :answer_type, null: false, default: "text"
      t.integer :points_value, null: false, default: 10
      t.datetime :closes_at, null: false

      t.timestamps
    end

    create_table :special_predictions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :special_question, null: false, foreign_key: true
      t.string :answer, null: false

      t.timestamps
    end

    add_index :special_questions, :key, unique: true
    add_index :special_predictions, %i[user_id special_question_id], unique: true
  end
end
