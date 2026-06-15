require "test_helper"

class PredictionCommentsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    prediction = Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)

    post prediction_comments_path(prediction), params: { prediction_comment: { body: "Boa" } }

    assert_redirected_to new_session_path
  end

  test "creates comment on revealed prediction" do
    player = user
    commenter = user(name: "Bia", email: "bia@example.com")
    game = match_record(kickoff_at: 1.day.from_now)
    prediction = Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)
    game.update!(kickoff_at: 1.minute.ago, status: "live")

    post session_path, params: { email: commenter.email, password: "secret123" }

    assert_difference "PredictionComment.count", 1 do
      post prediction_comments_path(prediction), params: { prediction_comment: { body: "Boa cravada" } }
    end

    assert_redirected_to mural_path(anchor: "mural")
  end

  test "rejects comment on hidden prediction" do
    player = user
    commenter = user(name: "Bia", email: "bia@example.com")
    game = match_record(kickoff_at: 1.day.from_now)
    prediction = Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)

    post session_path, params: { email: commenter.email, password: "secret123" }

    assert_no_difference "PredictionComment.count" do
      post prediction_comments_path(prediction), params: { prediction_comment: { body: "Boa cravada" } }
    end

    assert_redirected_to mural_path(anchor: "mural")
  end
end
