class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.string :external_id, null: false
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }
      t.datetime :kickoff_at, null: false
      t.string :status, null: false, default: "scheduled"
      t.integer :home_score
      t.integer :away_score
      t.string :stage
      t.string :group_name
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :matches, :external_id, unique: true
    add_index :matches, :kickoff_at
    add_index :matches, :status
  end
end
