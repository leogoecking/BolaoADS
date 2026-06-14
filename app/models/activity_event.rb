class ActivityEvent < ApplicationRecord
  EVENT_TYPES = %w[exact_score leader_changed ranking_drop only_believer no_hits big_climb underdog_hit].freeze

  belongs_to :user
  belongs_to :match
  belongs_to :prediction, optional: true
  has_many :activity_event_comments, dependent: :destroy
  has_many :activity_event_reactions, dependent: :destroy

  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :message, :dedupe_key, presence: true
  validates :dedupe_key, uniqueness: true

  scope :recent, -> {
    includes(
      :user,
      :activity_event_reactions,
      { activity_event_comments: :user },
      { match: %i[home_team away_team] },
      prediction: [:user, :match]
    )
      .order(created_at: :desc)
  }

  def reaction_counts
    activity_event_reactions.group_by(&:reaction_type).transform_values(&:size)
  end
end
