class PredictionSettlementService
  def initialize(prediction)
    @prediction = prediction
  end

  def call
    return unless prediction.match.finished?

    points = prediction.calculated_points
    settle_adcoins(points)
    prediction.update_columns(points: points, calculated_at: Time.current, updated_at: Time.current)
    AchievementUnlocker.new(prediction.user).call
  end

  private

  attr_reader :prediction

  def settle_adcoins(points)
    payout = points.positive? ? prediction.adcoins_wager * 2 : 0
    delta = payout - prediction.adcoins_payout
    unless delta.zero?
      prediction.user.increment!(:adcoins_balance, delta)
      AchievementUnlocker.refresh_adcoins_achievements!
    end
    prediction.update_columns(adcoins_payout: payout, adcoins_settled: true, updated_at: Time.current)
  end
end
