require "test_helper"

class LiveMatchStatsTest < ActiveSupport::TestCase
  class FakeStatsClient
    def stats(_event_id)
      {
        "event_id" => 8290,
        "stats" => {
          "home" => {
            "ball_possession" => 61,
            "expected_goals" => 0.04,
            "total_shots" => 1,
            "shots_on_target" => 1,
            "pass_accuracy_pct" => 84.6,
            "xg" => { "actual" => 0.036 }
          },
          "away" => {
            "ball_possession" => 39,
            "expected_goals" => 0.08,
            "total_shots" => 1,
            "shots_on_target" => 1,
            "pass_accuracy_pct" => 66.7,
            "xg" => { "actual" => 0.08 }
          }
        },
        "shotmap" => [{ "min" => 2 }, { "min" => 3 }],
        "momentum" => [{ "m" => 1 }]
      }
    end
  end

  test "normalizes comparable live stats" do
    game = match_record(status: "live", home_score: 0, away_score: 0)

    stats = Football::LiveMatchStats.new(game, client: FakeStatsClient.new).call
    possession = stats[:rows].find { |row| row[:key] == "ball_possession" }
    xg = stats[:rows].find { |row| row[:key] == "expected_goals" }

    assert_equal 8290, stats[:event_id]
    assert_equal 2, stats[:shot_count]
    assert_equal "61%", possession[:home_label]
    assert_equal "39%", possession[:away_label]
    assert_equal "0.04", xg[:home_label]
    assert_equal "0.08", xg[:away_label]
  end

  test "returns nil when stats are unavailable" do
    game = match_record(status: "live")
    client = Class.new do
      def stats(_event_id)
        { "stats" => {} }
      end
    end.new

    assert_nil Football::LiveMatchStats.new(game, client: client).call
  end
end
