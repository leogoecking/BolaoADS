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
    create_only_believer_event
    create_no_hits_event
    create_big_climb_event
    create_underdog_hit_events
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

  def create_only_believer_event
    winners = match.predictions.includes(:user).where("points > 0").to_a
    return unless winners.one?

    prediction = winners.first
    create_event(
      event_type: "only_believer",
      user: prediction.user,
      prediction: prediction,
      dedupe_key: "only_believer:#{match.id}:#{prediction.user_id}",
      message: "#{prediction.user.name} foi a unica pessoa que saiu com ponto em #{match.home_team.name} x #{match.away_team.name}. Pode pedir musica no mural."
    )
  end

  def create_no_hits_event
    predictions = match.predictions.includes(:user).to_a
    return if predictions.empty? || predictions.any? { |prediction| prediction.points == 3 }

    user = predictions.max_by(&:points).user
    create_event(
      event_type: "no_hits",
      user: user,
      dedupe_key: "no_hits:#{match.id}:#{match.home_score}-#{match.away_score}",
      message: "Ninguem cravou #{match.home_team.name} #{match.home_score}x#{match.away_score} #{match.away_team.name}. Rodada oficialmente liberada para desculpas."
    )
  end

  def create_big_climb_event
    current_positions = positions_for(User.ranking.to_a)
    climb = previous_positions.filter_map do |user_id, previous_position|
      current_position = current_positions[user_id]
      next if current_position.blank?

      positions_gained = previous_position - current_position
      next unless positions_gained.positive?

      [ user_id, positions_gained, previous_position, current_position ]
    end.max_by { |(_user_id, positions_gained, _previous_position, _current_position)| positions_gained }
    return if climb.blank?

    user_id, positions_gained, previous_position, current_position = climb
    user = User.find(user_id)
    AchievementUnlocker.new(user).unlock_big_climb!(positions_gained)
    create_event(
      event_type: "big_climb",
      user: user,
      dedupe_key: "big_climb:#{match.id}:#{user.id}:#{previous_position}-#{current_position}",
      message: "#{user.name} subiu #{positions_gained} posicoes de uma vez. O elevador social do bolao passou cheio."
    )
  end

  def create_underdog_hit_events
    return if match.underdog_team_id.blank? || match.actual_winner_team_id != match.underdog_team_id

    match.predictions.includes(:user).where("points > 0").find_each do |prediction|
      next unless prediction.predicted_winner_team_id == match.underdog_team_id

      create_event(
        event_type: "underdog_hit",
        user: prediction.user,
        prediction: prediction,
        dedupe_key: "underdog_hit:#{match.id}:#{prediction.id}",
        message: "#{prediction.user.name} acreditou na zebra #{match.underdog_team.name} e agora tem recibo para cobrar respeito."
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
