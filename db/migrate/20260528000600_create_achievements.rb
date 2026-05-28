class CreateAchievements < ActiveRecord::Migration[8.0]
  def change
    create_table :achievements do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description, null: false

      t.timestamps
    end

    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.datetime :unlocked_at, null: false

      t.timestamps
    end

    add_index :achievements, :key, unique: true
    add_index :user_achievements, %i[user_id achievement_id], unique: true
  end
end
