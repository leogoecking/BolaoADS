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

  def with_live_score_sync(result)
    original = Football::LiveScoreSync
    replacement = Class.new do
      define_singleton_method(:call) { result }
    end

    Football.send(:remove_const, :LiveScoreSync)
    Football.const_set(:LiveScoreSync, replacement)
    yield
  ensure
    Football.send(:remove_const, :LiveScoreSync)
    Football.const_set(:LiveScoreSync, original)
  end

  def with_live_match_stats(result)
    original = Football::LiveMatchStats
    replacement = Class.new do
      define_method(:initialize) do |_match|
      end

      define_method(:call) { result }
    end

    Football.send(:remove_const, :LiveMatchStats)
    Football.const_set(:LiveMatchStats, replacement)
    yield
  ensure
    Football.send(:remove_const, :LiveMatchStats)
    Football.const_set(:LiveMatchStats, original)
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
    assert_not_includes response.body, "Atividades do bolao"
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
    venue = Venue.create!(external_id: "1182", name: "MetLife Stadium", city: "East Rutherford", country: "USA")
    game.update!(group_name: "Group A", round_number: 1, venue: venue, weather: JSON.generate({ "temperature_c" => 22 }))

    post session_path, params: { email: player.email, password: "secret123" }
    get calendar_matches_path

    assert_response :success
    assert_includes response.body, "Todos os jogos"
    assert_includes response.body, "Group A"
    assert_includes response.body, "Rodada 1"
    assert_includes response.body, "MetLife Stadium"
  end

  test "shows knockout bracket page" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    game.update!(round_name: "Final", stage: "Final")

    post session_path, params: { email: player.email, password: "secret123" }
    get bracket_matches_path

    assert_response :success
    assert_includes response.body, "Chaveamento"
    assert_includes response.body, "Final"
  end

  test "shows groups page with fallback when standings are empty" do
    player = user

    post session_path, params: { email: player.email, password: "secret123" }
    with_empty_standings { get groups_matches_path }

    assert_response :success
    assert_includes response.body, "Fase de grupos"
    assert_includes response.body, "Tabela indispon"
  end

  test "syncs live scores as json" do
    player = user
    game = match_record(status: "live", home_score: 1, away_score: 0)

    post session_path, params: { email: player.email, password: "secret123" }
    with_live_score_sync({ synced_count: 1, changed_count: 1, skipped: false, last_synced_at: Time.zone.parse("2026-06-12T12:00:00Z") }) do
      post live_sync_matches_path
    end

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal 1, payload["synced_count"]
    assert_equal 1, payload["changed_count"]
    assert_equal false, payload["skipped"]
    assert_equal true, payload["has_live_matches"]
    assert_equal "live", game.reload.status
  end

  test "hides other users predictions before kickoff" do
    player = user
    other = user(name: "Carlos", email: "carlos@example.com")
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: other, match: game, home_score: 4, away_score: 4)

    post session_path, params: { email: player.email, password: "secret123" }
    get match_path(game)

    assert_response :success
    assert_includes response.body, "Ver palpites"
    assert_includes response.body, "Resenha"
    assert_includes response.body, "match-chat-drawer"
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
    assert_includes response.body, "Ver palpites"
    assert_includes response.body, "match-predictions-modal"
    assert_includes response.body, "Palpites revelados"
    assert_includes response.body, "Carlos"
    assert_includes response.body, "4 x 4"
  end

  test "shows stats modal button when live stats are available" do
    player = user
    game = match_record(kickoff_at: 1.minute.ago, status: "live", home_score: 0, away_score: 0)
    stats = {
      rows: [
        { key: "ball_possession", label: "Posse de bola", home_label: "55%", away_label: "45%" }
      ],
      shot_count: 2
    }

    post session_path, params: { email: player.email, password: "secret123" }
    with_live_match_stats(stats) { get match_path(game) }

    assert_response :success
    assert_includes response.body, "Ver estatisticas"
    assert_includes response.body, "match-stats-modal"
    assert_includes response.body, "Posse de bola"
  end
end
