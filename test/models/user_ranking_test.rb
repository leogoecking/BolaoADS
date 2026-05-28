require "test_helper"

class UserRankingTest < ActiveSupport::TestCase
  test "orders users by points and exact hits" do
    first = user(name: "Bruno", email: "bruno@example.com")
    second = user(name: "Carla", email: "carla@example.com")
    game = match_record(kickoff_at: 1.day.from_now, status: "scheduled")

    Prediction.create!(user: first, match: game, home_score: 2, away_score: 1)
    Prediction.create!(user: second, match: game, home_score: 1, away_score: 0)
    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)

    assert_equal [first.id, second.id], User.ranking.map(&:id)
  end
end
