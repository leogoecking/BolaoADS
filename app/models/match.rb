class Match < ApplicationRecord
  STATUSES = %w[scheduled live finished postponed].freeze

  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :underdog_team, class_name: "Team", optional: true
  belongs_to :venue, optional: true
  has_many :predictions, dependent: :destroy
  has_many :activity_events, dependent: :destroy
  has_many :match_messages, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :kickoff_at, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { includes(:home_team, :away_team, :venue).order(:kickoff_at) }

  after_save :score_predictions, if: :score_relevant_change?
  after_save :expire_group_standings_cache, if: :finished_score_relevant_change?

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

  def weather_details
    JSON.parse(weather.presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def weather_label
    details = weather_details
    temperature = details["temperature_c"]
    wind_speed = details["wind_speed"]
    description = details["description"]
    labels = []
    labels << "#{temperature}°C" if temperature.present?
    labels << "#{wind_speed} km/h vento" if wind_speed.present?
    labels << description if description.present?
    labels.join(" - ").presence
  end

  def recent_match_messages(limit: 60)
    match_messages.includes(:user).latest_window(limit).to_a.reverse
  end

  def important_live_incidents(limit: 12)
    live_incident_list.reject { |incident| period_start_incident?(incident) }.first(limit)
  end

  def live_clock_label
    return nil unless live?
    return nil if current_minute.blank? && period.blank?

    [ live_minute_label, localized_period.presence ].compact.join(" - ")
  end

  def localized_period
    case period.to_s.downcase
    when "1st_half", "first_half", "first half", "1h", "1t"
      "1T"
    when "2nd_half", "second_half", "second half", "2h", "2t"
      "2T"
    when "halftime", "half_time", "half time", "ht", "interval"
      "Intervalo"
    when "extra_time", "extra time", "et"
      "Prorrogacao"
    else
      period
    end
  end

  def score_label
    home_score.nil? ? "-" : "#{home_score} x #{away_score}"
  end

  def status_label
    return "Ao vivo" if live?
    return "Aberto" if open_for_predictions?
    return "Encerrado" if finished?

    status
  end

  def incident_title(incident)
    period_title = incident_period_title(incident)
    return period_title if period_title.present?

    incident["text"].presence || incident_type_label(incident) || "Lance"
  end

  def incident_meta(incident)
    return incident_period_meta(incident) if incident["type"].to_s == "period"
    return incident_injury_time_meta(incident) if incident["type"].to_s == "injuryTime"
    return incident_substitution_meta(incident) if incident["type"].to_s == "substitution"

    [
      incident_player_label(incident),
      incident_team_label(incident),
      incident_score_label(incident)
    ].compact.join(" - ")
  end

  def incident_minute_label(incident)
    return "0'" if first_half_start_incident?(incident)
    return "45'" if second_half_start_incident?(incident)

    incident["minute"].present? ? "#{incident["minute"]}'" : "--"
  end

  def incident_type_label(incident)
    type = incident["type"].to_s

    case type
    when "goal"
      incident["goal_type"] == "ownGoal" ? "Gol contra" : "Gol"
    when "card", "yellow_card"
      incident["card_type"] == "red" ? "Cartao vermelho" : "Cartao amarelo"
    when "red_card"
      "Cartao vermelho"
    when "substitution"
      "Substituicao"
    when "period"
      "Periodo"
    when "injuryTime"
      "Acrescimos"
    else
      type.humanize.presence
    end
  end

  def incident_player_label(incident)
    return if incident["player"].blank?

    "Jogador: #{incident["player"]}"
  end

  def incident_substitution_meta(incident)
    labels = [
      incident_player_in_label(incident),
      incident_player_out_label(incident),
      incident_team_label(incident)
    ].compact

    return labels.join(" - ") if labels.any?

    incident_team_label(incident)
  end

  def incident_player_in_label(incident)
    return if incident["player_in"].blank?

    "Entrou: #{incident["player_in"]}"
  end

  def incident_player_out_label(incident)
    return if incident["player_out"].blank?

    "Saiu: #{incident["player_out"]}"
  end

  def incident_team_label(incident)
    return if incident["is_home"].nil?

    team = ActiveModel::Type::Boolean.new.cast(incident["is_home"]) ? home_team : away_team
    return "Gol para: #{team.name}" if incident["goal_type"] == "ownGoal"

    "Time: #{team.name}"
  end

  def incident_score_label(incident)
    return if incident["home_score"].nil?

    "#{incident["home_score"]} x #{incident["away_score"]}"
  end

  def incident_period_title(incident)
    return unless incident["type"].to_s == "period"

    text = incident["text"].to_s.downcase
    return "Inicio do 1o tempo" if text.include?("first half")
    return "Inicio do 2o tempo" if text.include?("second half")
    return "Intervalo" if text.include?("half time") || text.include?("halftime") || text.include?("interval")
    return "Fim de jogo" if text.include?("full time")

    incident["text"].presence || "Periodo"
  end

  def incident_period_meta(incident)
    return "Bola rolando" if first_half_start_incident?(incident)
    return "Jogo no intervalo" if incident_period_title(incident) == "Intervalo"

    incident_score_label(incident)
  end

  def first_half_start_incident?(incident)
    incident["type"].to_s == "period" && incident["text"].to_s.downcase.include?("first half")
  end

  def second_half_start_incident?(incident)
    incident["type"].to_s == "period" && incident["text"].to_s.downcase.include?("second half")
  end

  def period_start_incident?(incident)
    first_half_start_incident?(incident) || second_half_start_incident?(incident)
  end

  def incident_injury_time_meta(incident)
    length = incident["length"].to_i
    return if length <= 0

    "+#{length} min de acrescimos"
  end

  def live_minute_label
    return if current_minute.blank?

    stoppage = active_stoppage_time
    return "#{stoppage[:base]}+#{stoppage[:elapsed]}'" if stoppage

    "#{current_minute}'"
  end

  def active_stoppage_time
    injury_time = live_incident_list.find { |incident| incident["type"].to_s == "injuryTime" }
    length = injury_time&.dig("length").to_i
    return if injury_time.blank? || length <= 0

    base = localized_period == "2T" ? 90 : 45
    elapsed = current_minute.to_i - base
    return if elapsed <= 0

    { base: base, elapsed: [ elapsed, length ].min }
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

  def finished_score_relevant_change?
    finished? && score_relevant_change?
  end

  def expire_group_standings_cache
    Rails.cache.delete(Football::GroupStandings::CACHE_KEY)
  end
end
