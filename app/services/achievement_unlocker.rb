class AchievementUnlocker
  def initialize(user)
    @user = user
  end

  def call
    Achievement.ensure_catalog!
    unlock!("mae_dina") if exact_hits >= 3
    unlock!("cacador_de_zebra") if zebra_hit?
    unlock!("zicador") if last_finished_predictions(5).size == 5 && last_finished_predictions(5).all? { |prediction| prediction.points.zero? }
    unlock!("pe_quente") if last_finished_predictions(5).size == 5 && last_finished_predictions(5).all? { |prediction| prediction.points.positive? }
    unlock!("geladeira") if three_scoreless_stages?
    unlock!("sniper") if sniper_hit?
  end

  def unlock_last_minute!(prediction)
    Achievement.ensure_catalog!
    return unless prediction.match.kickoff_at.present?

    timestamp = prediction.updated_at || Time.current
    window_start = prediction.match.kickoff_at - 20.minutes
    window_end = prediction.match.kickoff_at - 10.minutes
    unlock!("ultima_hora") if timestamp >= window_start && timestamp < window_end
  end

  private

  attr_reader :user

  def unlock!(key)
    achievement = Achievement.find_by!(key: key)
    UserAchievement.find_or_create_by!(user: user, achievement: achievement) do |user_achievement|
      user_achievement.unlocked_at = Time.current
    end
  end

  def exact_hits
    user.predictions.where(points: 3).count
  end

  def zebra_hit?
    user.predictions.joins(:match).where("predictions.points > 0").any? do |prediction|
      underdog_id = prediction.match.underdog_team_id
      next false unless underdog_id

      prediction.match.actual_winner_team_id == underdog_id &&
        prediction.predicted_winner_team_id == underdog_id
    end
  end

  def sniper_hit?
    user.predictions.joins(:match).where(points: 3, matches: { knockout: true }).exists?
  end

  def last_finished_predictions(limit)
    user.predictions
      .joins(:match)
      .where(matches: { status: "finished" })
      .includes(:match)
      .order("matches.kickoff_at DESC")
      .limit(limit)
  end

  def three_scoreless_stages?
    stage_points = user.predictions
      .joins(:match)
      .where(matches: { status: "finished" })
      .includes(:match)
      .group_by { |prediction| prediction.match.stage.presence || "Sem fase" }
      .map { |stage, predictions| [stage, predictions.sum(&:points), predictions.map { |prediction| prediction.match.kickoff_at }.max] }
      .sort_by { |(_, _, kickoff_at)| kickoff_at }
      .last(3)

    stage_points.size == 3 && stage_points.all? { |(_, points, _)| points.zero? }
  end
end
