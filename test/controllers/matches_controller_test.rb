require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    get matches_path

    assert_redirected_to new_session_path
  end

  test "shows matches to authenticated user" do
    player = user
    match_record

    post session_path, params: { email: player.email, password: "secret123" }
    get matches_path

    assert_response :success
    assert_includes response.body, "Jogos"
  end

  test "hides other users predictions before kickoff" do
    player = user
    other = user(name: "Carlos", email: "carlos@example.com")
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: other, match: game, home_score: 4, away_score: 4)

    post session_path, params: { email: player.email, password: "secret123" }
    get match_path(game)

    assert_response :success
    assert_includes response.body, "Palpites secretos"
    assert_not_includes response.body, "Carlos"
    assert_not_includes response.body, "4 x 4"
  end

  test "reveals predictions after kickoff" do
    player = user
    other = user(name: "Carlos", email: "carlos@example.com")
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: other, match: game, home_score: 4, away_score: 4)
    game.update!(kickoff_at: 1.minute.ago, status: "live")

    post session_path, params: { email: player.email, password: "secret123" }
    get match_path(game)

    assert_response :success
    assert_includes response.body, "Palpites revelados"
    assert_includes response.body, "Carlos"
    assert_includes response.body, "4 x 4"
  end
end
