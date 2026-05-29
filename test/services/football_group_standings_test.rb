require "test_helper"

class FootballGroupStandingsTest < ActiveSupport::TestCase
  class FakeClient
    def group_standings
      {
        "groups" => {
          "Group A" => [
            {
              "position" => 1,
              "team_id" => 451,
              "team_name" => "Mexico",
              "played" => 1,
              "won" => 1,
              "drawn" => 0,
              "lost" => 0,
              "gf" => 2,
              "ga" => 1,
              "gd" => 1,
              "pts" => 3,
              "live" => false
            }
          ]
        }
      }
    end
  end

  class FailingClient
    def group_standings
      raise Football::ApiClient::ApiError, "API fora"
    end
  end

  setup do
    Rails.cache.clear
  end

  test "normalizes BSD group standings payload" do
    standings = Football::GroupStandings.new(client: FakeClient.new).call

    mexico = standings.fetch("Group A").first
    assert_equal 451, mexico[:team_id]
    assert_equal "Mexico", mexico[:team_name]
    assert_equal 3, mexico[:points]
    assert_equal 1, mexico[:goal_difference]
  end

  test "returns empty standings when API fails" do
    standings = Football::GroupStandings.new(client: FailingClient.new).call

    assert_equal({}, standings)
  end
end
