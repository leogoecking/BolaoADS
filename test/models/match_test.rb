require "test_helper"

class MatchTest < ActiveSupport::TestCase
  test "finished match does not expose live clock and shows closed label" do
    match = match_record(
      kickoff_at: 1.day.ago,
      status: "finished",
      home_score: 2,
      away_score: 1
    )
    match.update!(current_minute: 96, period: "FT")

    assert_nil match.live_clock_label
    assert_equal "Encerrado", match.status_label
  end

  test "finishing a match expires group standings cache" do
    match = match_record(status: "live", home_score: 1, away_score: 1)
    Rails.cache.write(Football::GroupStandings::CACHE_KEY, { "stale" => [] })

    match.update!(current_minute: 80)

    assert Rails.cache.exist?(Football::GroupStandings::CACHE_KEY)

    match.update!(status: "finished", home_score: 2, away_score: 1)

    assert_not Rails.cache.exist?(Football::GroupStandings::CACHE_KEY)
  end
end
