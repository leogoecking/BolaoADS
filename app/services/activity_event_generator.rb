class ActivityEventGenerator
  RANKING_DROP_THRESHOLD = 3

  def initialize(match, previous_ranking:)
    @match = match
    @previous_positions = positions_for(previous_ranking)
  end

  def call
    return unless match.finished? && match.home_score.present? && match.away_score.present?

    create_exact_score_events
    create_leader_changed_event
    create_ranking_drop_events
  end

  private

  attr_reader :match, :previous_positions

  def create_exact_score_events
    match.predictions.includes(:user).where(points: 3).find_each do |prediction|
      create_event(
        event_type: "exact_score",
        user: prediction.user,
        prediction: prediction,
        dedupe_key: "exact_score:#{prediction.id}:#{match.home_score}-#{match.away_score}",
        message: "#{prediction.user.name} acertou o placar exato de #{match.home_team.name} #{match.home_score}x#{match.away_score} #{match.away_team.name}."
      )
    end
  end

  def create_leader_changed_event
    previous_leader_id = previous_positions.key(1)
    current_leader = User.ranking.first
    return if current_leader.blank? || current_leader.id == previous_leader_id

    create_event(
      event_type: "leader_changed",
      user: current_leader,
      dedupe_key: "leader_changed:#{match.id}:#{current_leader.id}",
      message: "#{current_leader.name} assumiu a lideranca."
    )
  end

  def create_ranking_drop_events
    current_positions = positions_for(User.ranking.to_a)

    previous_positions.each do |user_id, previous_position|
      current_position = current_positions[user_id]
      next if current_position.blank?

      drop = current_position - previous_position
      next if drop < RANKING_DROP_THRESHOLD

      user = User.find(user_id)
      prediction = user.predictions.find_by(match: match)
      team_name = prediction&.predicted_winner_team_id && Team.find_by(id: prediction.predicted_winner_team_id)&.name
      team_name ||= "no palpite"

      create_event(
        event_type: "ranking_drop",
        user: user,
        prediction: prediction,
        dedupe_key: "ranking_drop:#{match.id}:#{user.id}:#{previous_position}-#{current_position}",
        message: "#{user.name} perdeu #{drop} posicoes apos confiar demais #{team_name == "no palpite" ? team_name : "em #{team_name}"}."
      )
    end
  end

  def create_event(attributes)
    ActivityEvent.find_or_create_by!(dedupe_key: attributes.fetch(:dedupe_key)) do |event|
      event.event_type = attributes.fetch(:event_type)
      event.user = attributes.fetch(:user)
      event.match = match
      event.prediction = attributes[:prediction]
      event.message = attributes.fetch(:message)
    end
  end

  def positions_for(users)
    users.each_with_index.to_h { |user, index| [user.id, index + 1] }
  end
end
