require "test_helper"

class FootballBracketTest < ActiveSupport::TestCase
  test "uses only official knockout rounds" do
    round_of_16 = match_record(kickoff_at: 3.days.from_now)
    unknown_round = match_record(kickoff_at: 2.days.from_now)
    blank_round = match_record(kickoff_at: 1.day.from_now)

    round_of_16.update!(round_name: "Round of 16", stage: "Round of 16")
    unknown_round.update!(round_name: "Knockout stage", stage: "Knockout stage")
    blank_round.update!(round_name: nil, stage: nil)

    rounds = Football::Bracket.new(Match.ordered.to_a).call

    assert_equal [ "Oitavas" ], rounds.map { |round| round.fetch(:label) }
    assert_equal [ round_of_16 ], rounds.first.fetch(:matches)
  end
end
