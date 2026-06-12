class Match < ApplicationRecord
  STATUSES = %w[scheduled live finished postponed].freeze

  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :underdog_team, class_name: "Team", optional: true
  has_many :predictions, dependent: :destroy
  has_many :activity_events, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :kickoff_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { includes(:home_team, :away_team).order(:kickoff_at) }

  after_save :score_predictions, if: :score_relevant_change?

  def prediction_deadline
    kickoff_at - 10.minutes
  end

  def open_for_predictions?
    scheduled? && Time.current < prediction_deadline
  end

  def scheduled?
    status == "scheduled"
  end

  def live?
    status == "live"
  end

  def finished?
    status == "finished"
  end

  def live_incident_list
    JSON.parse(live_incidents.presence || "[]")
  rescue JSON::ParserError
    []
  end

  def live_clock_label
    return nil if current_minute.blank? && period.blank?

    [ current_minute.present? ? "#{current_minute}'" : nil, period.presence ].compact.join(" · ")
  end

  def score_predictions
    return unless finished? && home_score.present? && away_score.present?

    previous_ranking = User.ranking.to_a
    predictions.includes(:user).find_each { |prediction| PredictionSettlementService.new(prediction).call }
    ActivityEventGenerator.new(self, previous_ranking: previous_ranking).call
  end

  def actual_result
    result_for(home_score, away_score)
  end

  def result_for(home_goals, away_goals)
    return nil if home_goals.nil? || away_goals.nil?

    return "draw" if home_goals == away_goals
    home_goals > away_goals ? "home" : "away"
  end

  def actual_winner_team_id
    case actual_result
    when "home" then home_team_id
    when "away" then away_team_id
    end
  end

  def predictions_revealed?
    Time.current >= kickoff_at
  end

  private

  def score_relevant_change?
    saved_change_to_status? || saved_change_to_home_score? || saved_change_to_away_score?
  end
end
