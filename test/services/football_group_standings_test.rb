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
              "form" => "WWLDL",
              "xgf" => 1.5,
              "xga" => 0.1,
              "xgd" => 1.4,
              "xg_games" => 1,
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

  class EnglishNameClient
    def group_standings
      {
        "groups" => {
          "Group C" => [
            {
              "position" => 1,
              "team_id" => 473,
              "team_name" => "Scotland",
              "played" => 0,
              "won" => 0,
              "drawn" => 0,
              "lost" => 0,
              "gf" => 0,
              "ga" => 0,
              "gd" => 0,
              "pts" => 0,
              "live" => false
            }
          ]
        }
      }
    end
  end

  setup do
    Rails.cache.clear
  end

  test "normalizes BSD group standings payload" do
    mexico = Team.create!(code: "BSD-451", name: "Mexico")
    canada = Team.create!(code: "BSD-452", name: "Canada")
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: mexico,
      away_team: canada,
      kickoff_at: 1.day.ago,
      status: "finished",
      group_name: "Group A",
      home_score: 2,
      away_score: 1
    )
    standings = Football::GroupStandings.new(client: FakeClient.new).call

    row = standings.fetch("Group A").first
    assert_equal 451, row[:team_id]
    assert_equal "México", row[:team_name]
    assert_equal 3, row[:points]
    assert_equal 1, row[:goal_difference]
    assert_equal 1.4, row[:xgd]
  end

  test "returns empty standings when API fails" do
    standings = Football::GroupStandings.new(client: FailingClient.new).call

    assert_equal({}, standings)
  end

  test "fills missing api groups from local teams without calculating standings" do
    brazil = Team.create!(code: "BSD-463", name: "Brasil")
    morocco = Team.create!(code: "BSD-464", name: "Marrocos")
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: brazil,
      away_team: morocco,
      kickoff_at: 1.day.ago,
      status: "finished",
      group_name: "Group B",
      home_score: 1,
      away_score: 1
    )

    standings = Football::GroupStandings.new(client: FakeClient.new).call
    group_b = standings.fetch("Group B")

    assert_equal 2, group_b.size
    assert_equal [ 0, 0 ], group_b.map { |row| row[:points] }
    assert_equal [ 0, 0 ], group_b.map { |row| row[:played] }
  end

  test "completes incomplete api groups from local matches" do
    mexico = Team.create!(code: "BSD-451", name: "Mexico")
    canada = Team.create!(code: "BSD-452", name: "Canada")
    usa = Team.create!(code: "BSD-453", name: "USA")
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: mexico,
      away_team: canada,
      kickoff_at: 1.day.ago,
      status: "scheduled",
      group_name: "Group A"
    )
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: usa,
      away_team: canada,
      kickoff_at: 2.days.ago,
      status: "finished",
      group_name: "Group A",
      home_score: 2,
      away_score: 0
    )

    standings = Football::GroupStandings.new(client: FakeClient.new).call
    group_a = standings.fetch("Group A")

    assert_equal 3, group_a.size
    assert_equal "México", group_a.first[:team_name]
    assert_equal [ "Canada", "USA" ], group_a.drop(1).map { |row| row[:team_name] }
    assert_equal [ 3, 0, 0 ], group_a.map { |row| row[:points] }
  end

  test "does not duplicate local translated team and prefers local display identity" do
    scotland = Team.create!(code: "BSD-466", name: "Escócia")
    brazil = Team.create!(code: "BSD-463", name: "Brasil")
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: scotland,
      away_team: brazil,
      kickoff_at: 1.day.from_now,
      status: "scheduled",
      group_name: "Group C"
    )

    standings = Football::GroupStandings.new(client: EnglishNameClient.new).call
    group_c = standings.fetch("Group C")

    assert_equal 2, group_c.size
    assert_equal 1, group_c.count { |row| row[:team_name] == "Escócia" }
    assert_equal 466, group_c.first[:team_id]
  end

  test "uses local teams without calculated standings when api fails" do
    brazil = Team.create!(code: "BSD-463", name: "Brasil")
    morocco = Team.create!(code: "BSD-464", name: "Marrocos")
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: brazil,
      away_team: morocco,
      kickoff_at: 1.day.ago,
      status: "finished",
      group_name: "Group C",
      home_score: 2,
      away_score: 0
    )

    standings = Football::GroupStandings.new(client: FailingClient.new).call

    assert_equal [ "Brasil", "Marrocos" ], standings.fetch("Group C").map { |row| row[:team_name] }
    assert_equal [ 0, 0 ], standings.fetch("Group C").map { |row| row[:points] }
    assert_equal [ 0, 0 ], standings.fetch("Group C").map { |row| row[:played] }
  end
end
