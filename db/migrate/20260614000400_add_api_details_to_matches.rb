class AddApiDetailsToMatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :matches, :venue, foreign_key: true
    add_column :matches, :round_name, :string
    add_column :matches, :round_number, :integer
    add_column :matches, :is_neutral_ground, :boolean, default: false, null: false
    add_column :matches, :travel_distance_km, :integer
    add_column :matches, :weather, :text, default: "{}", null: false
    add_column :matches, :pitch_condition, :string
    add_column :matches, :attendance, :integer
    add_column :matches, :home_score_ht, :integer
    add_column :matches, :away_score_ht, :integer
    add_column :matches, :extra_time_score, :text
    add_column :matches, :penalty_shootout, :text
    add_column :matches, :home_coach_id, :integer
    add_column :matches, :away_coach_id, :integer
    add_column :matches, :referee_id, :integer

    add_index :matches, :round_name
    add_index :matches, :round_number
  end
end
