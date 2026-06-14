require "test_helper"

class ActivityEventCommentTest < ActiveSupport::TestCase
  test "requires body with max length" do
    event = activity_event

    comment = ActivityEventComment.new(user: user, activity_event: event, body: "")
    assert_not comment.valid?

    comment.body = "a" * 281
    assert_not comment.valid?

    comment.body = "Resenha liberada"
    assert comment.valid?
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
