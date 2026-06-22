require "test_helper"

class PredictionsControllerTest < ActionDispatch::IntegrationTest
  test "creates prediction and returns to safe path" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)

    post session_path, params: { email: player.email, password: "secret123" }

    assert_difference "Prediction.count", 1 do
      post match_prediction_path(game), params: {
        return_to: calendar_matches_path(period: "today"),
        prediction: { home_score: 2, away_score: 1, adcoins_wager: 10 }
      }
    end

    assert_redirected_to calendar_matches_path(period: "today")
  end

  test "updates prediction and ignores external return path" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: player, match: game, home_score: 1, away_score: 1, adcoins_wager: 5)

    post session_path, params: { email: player.email, password: "secret123" }
    patch match_prediction_path(game), params: {
      return_to: "https://example.com/phishing",
      prediction: { home_score: 2, away_score: 0, adcoins_wager: 7 }
    }

    assert_redirected_to matches_path
    assert_equal [ 2, 0, 7 ], player.predictions.find_by!(match: game).then { |prediction| [ prediction.home_score, prediction.away_score, prediction.adcoins_wager ] }
  end

  test "redirects back with alert when prediction is invalid" do
    player = user
    game = match_record(kickoff_at: 9.minutes.from_now)

    post session_path, params: { email: player.email, password: "secret123" }

    assert_no_difference "Prediction.count" do
      post match_prediction_path(game), params: {
        return_to: calendar_matches_path(period: "today"),
        prediction: { home_score: 2, away_score: 1, adcoins_wager: 0 }
      }
    end

    assert_redirected_to calendar_matches_path(period: "today")
    assert_equal "Palpites encerrados para esta partida", flash[:alert]
  end

  test "renders match page on invalid prediction without return path" do
    player = user
    game = match_record(kickoff_at: 9.minutes.from_now)

    post session_path, params: { email: player.email, password: "secret123" }

    assert_no_difference "Prediction.count" do
      post match_prediction_path(game), params: {
        prediction: { home_score: 2, away_score: 1, adcoins_wager: 0 }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Palpites encerrados para esta partida"
    assert_includes response.body, game.home_team.name
  end
end
