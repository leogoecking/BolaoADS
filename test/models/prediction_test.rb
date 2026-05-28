require "test_helper"

class PredictionTest < ActiveSupport::TestCase
  test "accepts prediction before ten minute deadline" do
    prediction = Prediction.new(user: user, match: match_record(kickoff_at: 11.minutes.from_now), home_score: 2, away_score: 1)

    assert prediction.valid?
  end

  test "rejects prediction inside ten minute deadline" do
    prediction = Prediction.new(user: user, match: match_record(kickoff_at: 9.minutes.from_now), home_score: 2, away_score: 1)

    assert_not prediction.valid?
    assert_includes prediction.errors[:base], "Palpites encerrados para esta partida"
  end

  test "allows one prediction per user and match" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)

    Prediction.create!(user: player, match: game, home_score: 1, away_score: 0)
    duplicate = Prediction.new(user: player, match: game, home_score: 2, away_score: 0)

    assert_not duplicate.valid?
  end

  test "scores exact prediction with three points" do
    game = match_record(kickoff_at: 1.day.from_now, status: "scheduled")
    prediction = Prediction.create!(user: user, match: game, home_score: 2, away_score: 1)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)

    assert_equal 3, prediction.reload.points
  end

  test "scores correct result with one point" do
    game = match_record(kickoff_at: 1.day.from_now, status: "scheduled")
    prediction = Prediction.create!(user: user, match: game, home_score: 3, away_score: 1)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)

    assert_equal 1, prediction.reload.points
  end
end
