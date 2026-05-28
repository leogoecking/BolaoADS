class Team < ApplicationRecord
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, inverse_of: :home_team, dependent: :restrict_with_exception
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, inverse_of: :away_team, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
end
