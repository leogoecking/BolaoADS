class User < ApplicationRecord
  has_secure_password

  has_many :predictions, dependent: :destroy
  has_many :activity_events, dependent: :destroy
  has_many :prediction_comments, dependent: :destroy
  has_many :match_messages, dependent: :destroy
  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements
  has_many :special_predictions, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def self.ranking
    left_joins(:predictions)
      .select(
        "users.*",
        "COALESCE(SUM(predictions.points), 0) AS total_points",
        "COALESCE(SUM(CASE WHEN predictions.points = 3 THEN 1 ELSE 0 END), 0) AS exact_hits",
        "COALESCE(SUM(CASE WHEN predictions.points > 0 THEN 1 ELSE 0 END), 0) AS result_hits"
      )
      .group("users.id")
      .order(Arel.sql("total_points DESC, exact_hits DESC, result_hits DESC, users.name ASC"))
  end
end
