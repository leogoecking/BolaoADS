require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  def with_empty_standings
    original = Football::GroupStandings
    replacement = Class.new do
      def call
        {}
      end
    end

    Football.send(:remove_const, :GroupStandings)
    Football.const_set(:GroupStandings, replacement)
    yield
  ensure
    Football.send(:remove_const, :GroupStandings)
    Football.const_set(:GroupStandings, original)
  end

  test "redirects unauthenticated user" do
    get matches_path

    assert_redirected_to new_session_path
  end

  test "shows matches to authenticated user" do
    player = user
    match_record

    post session_path, params: { email: player.email, password: "secret123" }
    with_empty_standings { get matches_path }

    assert_response :success
    assert_includes response.body, "Jogos"
  end

  test "separates today and upcoming matches on index" do
    player = user
    travel_to Time.zone.local(2026, 6, 11, 10, 0, 0) do
      match_record(kickoff_at: 2.hours.from_now)
      match_record(kickoff_at: 2.days.from_now)

      post session_path, params: { email: player.email, password: "secret123" }
      with_empty_standings { get matches_path }

      assert_response :success
      assert_includes response.body, "Jogos do dia"
      assert_includes response.body, "Próximos jogos"
      assert_includes response.body, "Calend"
      assert_not_includes response.body, "Tabela de grupos"
    end
  end

  test "shows full calendar grouped by stage" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    game.update!(group_name: "Group A")

    post session_path, params: { email: player.email, password: "secret123" }
    get calendar_matches_path

    assert_response :success
    assert_includes response.body, "Todos os jogos"
    assert_includes response.body, "Group A"
  end

  test "shows groups page with fallback when standings are empty" do
    player = user

    post session_path, params: { email: player.email, password: "secret123" }
    with_empty_standings { get groups_matches_path }

    assert_response :success
    assert_includes response.body, "Fase de grupos"
    assert_includes response.body, "Tabela indispon"
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
