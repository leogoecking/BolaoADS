class Prediction < ApplicationRecord
  belongs_to :user
  belongs_to :match

  validates :user_id, uniqueness: { scope: :match_id }
  validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :adcoins_wager, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :user_has_available_adcoins
  validate :match_accepts_predictions, on: %i[create update]

  after_save :reserve_adcoins, if: :saved_change_to_adcoins_wager?
  after_save :unlock_last_minute

  def calculate_points!
    PredictionSettlementService.new(self).call
  end

  def calculated_points
    return 0 unless match.finished? && match.home_score.present? && match.away_score.present?
    return 3 if home_score == match.home_score && away_score == match.away_score

    match.result_for(home_score, away_score) == match.actual_result ? 1 : 0
  end

  def predicted_result
    match.result_for(home_score, away_score)
  end

  def predicted_winner_team_id
    case predicted_result
    when "home" then match.home_team_id
    when "away" then match.away_team_id
    end
  end

  private

  def match_accepts_predictions
    errors.add(:base, "Palpites encerrados para esta partida") unless match&.open_for_predictions?
  end

  def user_has_available_adcoins
    previous_wager = adcoins_wager_was || 0
    available = user&.adcoins_balance.to_i + previous_wager
    errors.add(:adcoins_wager, "nao pode passar do saldo disponivel") if adcoins_wager.to_i > available
  end

  def reserve_adcoins
    old_wager, new_wager = saved_change_to_adcoins_wager
    delta = new_wager.to_i - old_wager.to_i
    return if delta.zero?

    user.increment!(:adcoins_balance, -delta)
  end

  def unlock_last_minute
    AchievementUnlocker.new(user).unlock_last_minute!(self)
  end
end
