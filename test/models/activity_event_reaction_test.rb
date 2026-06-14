require "test_helper"

class ActivityEventReactionTest < ActiveSupport::TestCase
  test "allows configured reaction types only" do
    reaction = ActivityEventReaction.new(user: user, activity_event: activity_event, reaction_type: "kkkk")
    assert reaction.valid?

    reaction.reaction_type = "spam"
    assert_not reaction.valid?
  end

  test "does not allow duplicate user reaction type for same event" do
    player = user
    event = activity_event
    ActivityEventReaction.create!(user: player, activity_event: event, reaction_type: "zicou")

    duplicate = ActivityEventReaction.new(user: player, activity_event: event, reaction_type: "zicou")
    assert_not duplicate.valid?
  end

  private

  def activity_event
    ActivityEvent.create!(
      event_type: "leader_changed",
      user: user(email: "#{SecureRandom.hex(4)}@example.com"),
      match: match_record,
      message: "Ana assumiu a lideranca.",
      dedupe_key: SecureRandom.uuid
    )
  end
end
