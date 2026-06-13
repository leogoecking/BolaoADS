require "test_helper"

class FootballSyncTest < ActiveSupport::TestCase
  class FakeClient
    def matches
      [
        {
          "id" => "fixture-1",
          "home_team_id" => 463,
          "home_team" => "Brazil",
          "away_team_id" => 464,
          "away_team" => "Morocco",
          "event_date" => "2026-06-11T19:00:00Z",
          "status" => "notstarted"
        }
      ]
    end
  end

  class FakeApiFootballClient < Football::ApiFootballClient
    def initialize(payload)
      super(api_key: "test-key")
      @payload = payload
    end

    private

    def get_json(_path)
      @payload
    end
  end

  class FakeLiveClient
    def live_matches
      [
        {
          "id" => "live-1",
          "home_team_id" => 463,
          "home_team" => "Brazil",
          "away_team_id" => 464,
          "away_team" => "Morocco",
          "event_date" => "2026-06-13T19:00:00Z",
          "status" => "live",
          "home_score" => 1,
          "away_score" => 0
        }
      ]
    end

    def matches
      raise "full sync should not run"
    end
  end

  class FakeBsdLiveClient < Football::ApiClient
    def initialize(payload)
      super(api_key: "test-key")
      @payload = payload
    end

    private

    def get_json(_path)
      @payload
    end
  end

  class FakeBsdPathClient < Football::ApiClient
    attr_reader :requested_path

    def initialize
      super(api_key: "test-key")
    end

    private

    def get_json(path)
      @requested_path = path
      { "events" => [] }
    end
  end

  class FakeBsdLiveWithIncidentsClient
    def live_matches
      [
        {
          "id" => "live-bsd-2",
          "home_team" => "Brazil",
          "away_team" => "Morocco",
          "event_date" => "2026-06-13T19:00:00Z",
          "status" => "inprogress",
          "period" => "2nd_half",
          "current_minute" => 73,
          "home_score" => 2,
          "away_score" => 1
        }
      ]
    end

    def incidents(_event_id)
      [
        { "minute" => 73, "type" => "goal", "text" => "Goal", "player" => "F. Balogun", "is_home" => true, "home_score" => 2, "away_score" => 1 },
        { "minute" => 70, "type" => "card", "player" => "J. Hakimi", "is_home" => false, "card_type" => "yellow" },
        { "minute" => 45, "type" => "injuryTime", "length" => 4 }
      ]
    end
  end

  class FakeBsdLiveWithVariantIncidentsClient
    def live_matches
      [
        {
          "id" => "live-bsd-3",
          "home_team" => "Brazil",
          "away_team" => "Morocco",
          "event_date" => "2026-06-13T19:00:00Z",
          "status" => "inprogress",
          "clock" => { "minute" => "74", "period" => "2nd_half" },
          "homeScore" => 2,
          "awayScore" => 1
        }
      ]
    end

    def incidents(_event_id)
      [
        { "time" => { "minute" => "72" }, "incidentType" => "goal", "description" => "Goal", "score" => { "home" => 2, "away" => 1 } },
        { "minute" => 72, "type" => "goal", "text" => "Goal", "home_score" => 2, "away_score" => 1 },
        { "minute" => "15'", "category" => "yellow_card", "label" => "Yellow card" }
      ]
    end
  end

  class FakeBsdLiveWithFailedIncidentsClient
    def live_matches
      [
        {
          "id" => "live-bsd-4",
          "home_team" => "Brazil",
          "away_team" => "Morocco",
          "event_date" => "2026-06-13T19:00:00Z",
          "status" => "inprogress",
          "home_score" => 1,
          "away_score" => 1
        }
      ]
    end

    def incidents(_event_id)
      raise Football::ApiClient::ApiError, "temporarily unavailable"
    end
  end

  test "api client rejects missing key before requesting matches" do
    client = Football::ApiClient.new(api_key: nil)

    error = assert_raises(Football::ApiClient::ApiError) { client.matches }

    assert_equal "FOOTBALL_API_KEY nao configurada", error.message
  end

  test "bsd api client returns live matches" do
    client = FakeBsdLiveClient.new(
      "count" => 1,
      "events" => [
        {
          "id" => "live-bsd-1",
          "home_team" => "Brazil",
          "away_team" => "Morocco",
          "home_score" => 1,
          "away_score" => 0,
          "status" => "live"
        }
      ]
    )

    live_match = client.live_matches.first

    assert_equal "live-bsd-1", live_match["id"]
    assert_equal 1, live_match["home_score"]
    assert_equal "live", live_match["status"]
  end

  test "bsd api client falls back to default live path when env path is blank" do
    previous_path = ENV["FOOTBALL_API_LIVE_PATH"]
    ENV["FOOTBALL_API_LIVE_PATH"] = ""
    client = FakeBsdPathClient.new

    client.live_matches

    assert_equal Football::ApiClient::DEFAULT_LIVE_PATH, client.requested_path
  ensure
    ENV["FOOTBALL_API_LIVE_PATH"] = previous_path
  end

  test "bsd api client requests event stats" do
    client = FakeBsdPathClient.new

    client.stats("8290")

    assert_equal "events/8290/stats/", client.requested_path
  end

  test "api football client rejects missing key before requesting matches" do
    client = Football::ApiFootballClient.new(api_key: nil)

    error = assert_raises(Football::ApiClient::ApiError) { client.matches }

    assert_equal "API_FOOTBALL_KEY nao configurada", error.message
  end

  test "client factory selects api football provider" do
    previous_provider = ENV["FOOTBALL_API_PROVIDER"]
    ENV["FOOTBALL_API_PROVIDER"] = "api_football"

    assert_instance_of Football::ApiFootballClient, Football::ClientFactory.build
  ensure
    ENV["FOOTBALL_API_PROVIDER"] = previous_provider
  end

  test "synchronizer imports matches and returns count" do
    count = Football::MatchSynchronizer.new(client: FakeClient.new).call

    imported = Match.find_by!(external_id: "fixture-1")
    assert_equal 1, count
    assert_equal "Brasil", imported.home_team.name
    assert_equal "Marrocos", imported.away_team.name
    assert_equal "scheduled", imported.status
  end

  test "api football payloads are normalized and imported" do
    client = FakeApiFootballClient.new(
      "response" => [
        {
          "fixture" => {
            "id" => 123,
            "date" => "2026-06-13T19:00:00Z",
            "status" => { "short" => "2H" }
          },
          "league" => { "round" => "Group C - 1" },
          "teams" => {
            "home" => { "id" => 463, "name" => "Brazil" },
            "away" => { "id" => 464, "name" => "Morocco" }
          },
          "goals" => { "home" => 2, "away" => 1 }
        }
      ]
    )

    count = Football::MatchSynchronizer.new(client: client).call
    imported = Match.find_by!(external_id: "api-football-123")

    assert_equal 1, count
    assert_equal "Brasil", imported.home_team.name
    assert_equal "Marrocos", imported.away_team.name
    assert_equal "live", imported.status
    assert_equal 2, imported.home_score
    assert_equal 1, imported.away_score
  end

  test "api football client reports api body errors" do
    client = FakeApiFootballClient.new(
      "errors" => { "plan" => "Free plans do not have access to this season" },
      "response" => []
    )

    error = assert_raises(Football::ApiClient::ApiError) { client.matches }

    assert_includes error.message, "API-FOOTBALL retornou erro"
    assert_includes error.message, "Free plans"
  end

  test "api football payload updates existing match by teams and kickoff" do
    home = Team.create!(code: "BRA", name: "Brasil")
    away = Team.create!(code: "MAR", name: "Marrocos")
    existing = Match.create!(
      external_id: "bsd-fixture-1",
      home_team: home,
      away_team: away,
      kickoff_at: Time.zone.parse("2026-06-13T19:00:00Z"),
      status: "scheduled"
    )
    client = FakeApiFootballClient.new(
      "response" => [
        {
          "fixture" => {
            "id" => 123,
            "date" => "2026-06-13T19:00:00Z",
            "status" => { "short" => "1H" }
          },
          "league" => { "round" => "Group C - 1" },
          "teams" => {
            "home" => { "id" => 463, "name" => "Brazil" },
            "away" => { "id" => 464, "name" => "Morocco" }
          },
          "goals" => { "home" => 1, "away" => 0 }
        }
      ]
    )

    Football::MatchSynchronizer.new(client: client).call
    existing.reload

    assert_equal 1, Match.where(home_team: home, away_team: away).count
    assert_equal "bsd-fixture-1", existing.external_id
    assert_equal "live", existing.status
    assert_equal 1, existing.home_score
    assert_equal 0, existing.away_score
  end

  test "synchronizer can sync live matches only" do
    count = Football::MatchSynchronizer.new(client: FakeLiveClient.new, live_only: true).call
    imported = Match.find_by!(external_id: "live-1")

    assert_equal 1, count
    assert_equal "live", imported.status
    assert_equal 1, imported.home_score
    assert_equal 0, imported.away_score
  end

  test "synchronizer stores live clock and incidents" do
    count = Football::MatchSynchronizer.new(client: FakeBsdLiveWithIncidentsClient.new, live_only: true).call
    imported = Match.find_by!(external_id: "live-bsd-2")

    assert_equal 1, count
    assert_equal "live", imported.status
    assert_equal 73, imported.current_minute
    assert_equal "2nd_half", imported.period
    assert_equal "73' - 2T", imported.live_clock_label
    assert_equal "Goal", imported.live_incident_list.first["text"]
    assert_equal "F. Balogun", imported.live_incident_list.first["player"]
    assert_equal true, imported.live_incident_list.first["is_home"]
    assert_equal "Jogador: F. Balogun - Time: Brasil - 2 x 1", imported.incident_meta(imported.live_incident_list.first)
    assert_equal "Cartao amarelo", imported.incident_title(imported.live_incident_list.second)
    assert_equal "Jogador: J. Hakimi - Time: Marrocos", imported.incident_meta(imported.live_incident_list.second)
    assert_equal 4, imported.live_incident_list.find { |incident| incident["type"] == "injuryTime" }["length"]
    assert imported.live_incidents_synced_at.present?
  end

  test "synchronizer normalizes variant live payload and deduplicates incidents" do
    count = Football::MatchSynchronizer.new(client: FakeBsdLiveWithVariantIncidentsClient.new, live_only: true).call
    imported = Match.find_by!(external_id: "live-bsd-3")
    incidents = imported.live_incident_list

    assert_equal 1, count
    assert_equal "live", imported.status
    assert_equal 74, imported.current_minute
    assert_equal "2nd_half", imported.period
    assert_equal "74' - 2T", imported.live_clock_label
    assert_equal 2, imported.home_score
    assert_equal 1, imported.away_score
    assert_equal 2, incidents.size
    assert_equal 72, incidents.first["minute"]
    assert_equal "Goal", incidents.first["text"]
  end

  test "incident metadata labels own goal beneficiary without mislabeling player team" do
    game = match_record(status: "live")
    incident = { "type" => "goal", "goal_type" => "ownGoal", "player" => "D. Bobadilla", "is_home" => true, "home_score" => 1, "away_score" => 0 }

    assert_equal "Gol contra", game.incident_title(incident)
    assert_equal "Jogador: D. Bobadilla - Gol para: #{game.home_team.name} - 1 x 0", game.incident_meta(incident)
  end

  test "period incidents show clearer timeline labels" do
    game = match_record(status: "live")
    first_half = { "type" => "period", "text" => "First half", "minute" => 45, "home_score" => 1, "away_score" => 0 }
    halftime = { "type" => "period", "text" => "Half time", "minute" => 45, "home_score" => 1, "away_score" => 0 }
    second_half = { "type" => "period", "text" => "Second half", "minute" => 45, "home_score" => 1, "away_score" => 0 }
    game.update!(live_incidents: JSON.generate([first_half, halftime, second_half]))

    assert_equal "0'", game.incident_minute_label(first_half)
    assert_equal "Inicio do 1o tempo", game.incident_title(first_half)
    assert_equal "Bola rolando", game.incident_meta(first_half)
    assert_equal "45'", game.incident_minute_label(halftime)
    assert_equal "Intervalo", game.incident_title(halftime)
    assert_equal "Jogo no intervalo", game.incident_meta(halftime)
    assert_equal "45'", game.incident_minute_label(second_half)
    assert_equal "Inicio do 2o tempo", game.incident_title(second_half)
    assert_equal [halftime], game.important_live_incidents
  end

  test "injury time incident enriches live clock and timeline" do
    game = match_record(status: "live")
    game.update!(
      current_minute: 46,
      period: "1st_half",
      live_incidents: JSON.generate([{ "type" => "injuryTime", "minute" => 45, "length" => 5 }])
    )
    incident = game.live_incident_list.first

    assert_equal "45+1' - 1T", game.live_clock_label
    assert_equal "45'", game.incident_minute_label(incident)
    assert_equal "Acrescimos", game.incident_title(incident)
    assert_equal "+5 min de acrescimos", game.incident_meta(incident)
  end

  test "synchronizer preserves existing incidents when live incident fetch fails" do
    home = Team.create!(code: "BRA", name: "Brasil")
    away = Team.create!(code: "MAR", name: "Marrocos")
    existing = Match.create!(
      external_id: "live-bsd-4",
      home_team: home,
      away_team: away,
      kickoff_at: Time.zone.parse("2026-06-13T19:00:00Z"),
      status: "live",
      live_incidents: JSON.generate([{ "minute" => 10, "type" => "goal", "text" => "Goal" }])
    )

    Football::MatchSynchronizer.new(client: FakeBsdLiveWithFailedIncidentsClient.new, live_only: true).call

    assert_equal "Goal", existing.reload.live_incident_list.first["text"]
  end

  test "synchronizer updates existing api team names to portuguese" do
    Team.create!(code: "BSD-467", name: "Germany")

    Football::MatchSynchronizer.new(client: Class.new do
      def matches
        [
          {
            "id" => "fixture-2",
            "home_team_id" => 467,
            "home_team" => "Germany",
            "away_team_id" => 470,
            "away_team" => "Japan",
            "event_date" => "2026-06-12T19:00:00Z",
            "status" => "notstarted"
          }
        ]
      end
    end.new).call

    assert_equal "Alemanha", Team.find_by!(code: "BSD-467").name
    assert_equal "Japão", Team.find_by!(code: "BSD-470").name
  end
end
