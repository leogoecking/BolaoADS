class AchievementUnlocker
  def self.refresh_adcoins_achievements!
    Achievement.ensure_catalog!

    leader_balance = User.maximum(:adcoins_balance).to_i
    users = User.where("adcoins_balance >= ?", 1_000)
    users = users.or(User.where(adcoins_balance: leader_balance)) if leader_balance.positive?
    users.find_each { |user| new(user).unlock_adcoins! }
  end

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
    unlock!("maratonista_grupos") if group_stage_predictions_count >= 30
    unlock!("nao_dormiu_no_ponto") if full_day_predicted?
    unlock!("all_in_consciente") if all_in_hit?
    unlock!("so_passou_raiva") if finished_misses_count >= 10
    unlock!("sobreviveu_mata_mata") if knockout_hit?
    unlock_adcoins!
  end

  def unlock_last_minute!(prediction)
    Achievement.ensure_catalog!
    return unless prediction.match.kickoff_at.present?

    timestamp = prediction.updated_at || Time.current
    window_start = prediction.match.kickoff_at - 20.minutes
    window_end = prediction.match.kickoff_at - 10.minutes
    unlock!("ultima_hora") if timestamp >= window_start && timestamp < window_end
  end

  def unlock_big_climb!(positions_gained)
    Achievement.ensure_catalog!
    unlock!("cheirinho_lideranca") if positions_gained.to_i >= 3
  end

  def unlock_adcoins!
    Achievement.ensure_catalog!
    unlock!("magnata_do_palpite") if adcoins_leader?
    unlock!("milionario_de_mentira") if user.adcoins_balance.to_i >= 1_000
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

  def knockout_hit?
    user.predictions.joins(:match).where(matches: { knockout: true }).where("predictions.points > 0").exists?
  end

  def all_in_hit?
    user.predictions.where("adcoins_wager >= 100 AND points > 0").exists?
  end

  def adcoins_leader?
    leader_balance = User.maximum(:adcoins_balance).to_i

    leader_balance.positive? && user.adcoins_balance.to_i == leader_balance
  end

  def finished_misses_count
    user.predictions.joins(:match).where(points: 0, matches: { status: "finished" }).count
  end

  def group_stage_predictions_count
    user.predictions.joins(:match).where(matches: { stage: "Fase de grupos" }).count
  end

  def full_day_predicted?
    predicted_match_ids_by_date = user.predictions.includes(:match).group_by { |prediction| prediction.match.kickoff_at.to_date }.transform_values do |predictions|
      predictions.map(&:match_id)
    end

    predicted_match_ids_by_date.any? do |date, predicted_match_ids|
      day_match_ids = Match.where(kickoff_at: date.all_day).pluck(:id)
      day_match_ids.any? && (day_match_ids - predicted_match_ids).empty?
    end
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
