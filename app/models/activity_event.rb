class ActivityEvent < ApplicationRecord
  EVENT_TYPES = %w[exact_score leader_changed ranking_drop].freeze

  belongs_to :user
  belongs_to :match
  belongs_to :prediction, optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :message, :dedupe_key, presence: true
  validates :dedupe_key, uniqueness: true

  scope :recent, -> {
    includes(:user, { match: %i[home_team away_team] }, prediction: [:user, :match, { prediction_comments: :user }])
      .order(created_at: :desc)
  }
end
