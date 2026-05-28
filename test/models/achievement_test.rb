require "test_helper"

class AchievementTest < ActiveSupport::TestCase
  test "unlocks last minute achievement between twenty and ten minutes" do
    player = user
    game = match_record(kickoff_at: 15.minutes.from_now)

    travel_to(game.kickoff_at - 15.minutes) do
      Prediction.create!(user: player, match: game, home_score: 1, away_score: 0)
    end

    assert_includes player.achievements.pluck(:key), "ultima_hora"
  end

  test "unlocks mae dina after three exact scores" do
    player = user

    3.times do
      game = match_record(kickoff_at: 1.day.from_now)
      Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)
      game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)
    end

    assert_includes player.achievements.pluck(:key), "mae_dina"
  end
end
