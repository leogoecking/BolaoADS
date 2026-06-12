require "test_helper"

class PredictionCommentTest < ActiveSupport::TestCase
  test "accepts comment on revealed prediction" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    prediction = Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)
    game.update!(kickoff_at: 1.minute.ago, status: "live")

    comment = PredictionComment.new(user: user(name: "Bia", email: "bia@example.com"), prediction: prediction, body: "Cravou bonito")

    assert comment.valid?
  end

  test "rejects blank and long comments" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    prediction = Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)
    game.update!(kickoff_at: 1.minute.ago, status: "live")

    blank_comment = PredictionComment.new(user: player, prediction: prediction, body: "")
    long_comment = PredictionComment.new(user: player, prediction: prediction, body: "a" * 281)

    assert_not blank_comment.valid?
    assert_not long_comment.valid?
  end

  test "rejects comment before prediction is revealed" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    prediction = Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)

    comment = PredictionComment.new(user: player, prediction: prediction, body: "Ainda secreto")

    assert_not comment.valid?
    assert_includes comment.errors[:base], "Palpite ainda nao revelado"
  end
end
