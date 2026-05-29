require "test_helper"

class FootballSyncTest < ActiveSupport::TestCase
  class FakeClient
    def matches
      [
        {
          "id" => "fixture-1",
          "home_team_id" => 463,
          "home_team" => "Brasil",
          "away_team_id" => 464,
          "away_team" => "Argentina",
          "event_date" => "2026-06-11T19:00:00Z",
          "status" => "notstarted"
        }
      ]
    end
  end

  test "api client rejects missing key before requesting matches" do
    client = Football::ApiClient.new(api_key: nil)

    error = assert_raises(Football::ApiClient::ApiError) { client.matches }

    assert_equal "FOOTBALL_API_KEY nao configurada", error.message
  end

  test "synchronizer imports matches and returns count" do
    count = Football::MatchSynchronizer.new(client: FakeClient.new).call

    imported = Match.find_by!(external_id: "fixture-1")
    assert_equal 1, count
    assert_equal "Brasil", imported.home_team.name
    assert_equal "Argentina", imported.away_team.name
    assert_equal "scheduled", imported.status
  end
end
