require "test_helper"

class AdcoinsTest < ActiveSupport::TestCase
  test "reserves wager when prediction is saved" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)

    Prediction.create!(user: player, match: game, home_score: 2, away_score: 1, adcoins_wager: 20)

    assert_equal 80, player.reload.adcoins_balance
  end

  test "rejects wager above available balance" do
    prediction = Prediction.new(user: user, match: match_record(kickoff_at: 1.day.from_now), home_score: 2, away_score: 1, adcoins_wager: 101)

    assert_not prediction.valid?
  end

  test "pays double wager when prediction scores" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: player, match: game, home_score: 2, away_score: 1, adcoins_wager: 20)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)

    assert_equal 120, player.reload.adcoins_balance
  end
end
