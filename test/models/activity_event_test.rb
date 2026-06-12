require "test_helper"

class ActivityEventTest < ActiveSupport::TestCase
  test "requires unique dedupe key" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)

    ActivityEvent.create!(
      event_type: "leader_changed",
      user: player,
      match: game,
      message: "Ana assumiu a lideranca.",
      dedupe_key: "leader:1"
    )

    duplicate = ActivityEvent.new(
      event_type: "leader_changed",
      user: player,
      match: game,
      message: "Ana assumiu a lideranca.",
      dedupe_key: "leader:1"
    )

    assert_not duplicate.valid?
  end
end
