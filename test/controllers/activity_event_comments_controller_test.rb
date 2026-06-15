require "test_helper"

class ActivityEventCommentsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    event = activity_event

    post activity_event_comments_path(event), params: { activity_event_comment: { body: "Boa" } }

    assert_redirected_to new_session_path
  end

  test "creates comment on activity event without prediction" do
    commenter = user(name: "Bia", email: "bia@example.com")
    event = activity_event

    post session_path, params: { email: commenter.email, password: "secret123" }

    assert_difference "ActivityEventComment.count", 1 do
      post activity_event_comments_path(event), params: { activity_event_comment: { body: "Corneta registrada" } }
    end

    assert_redirected_to mural_path(anchor: "mural")
  end

  test "rejects invalid comment" do
    commenter = user(name: "Bia", email: "bia@example.com")
    event = activity_event

    post session_path, params: { email: commenter.email, password: "secret123" }

    assert_no_difference "ActivityEventComment.count" do
      post activity_event_comments_path(event), params: { activity_event_comment: { body: "" } }
    end

    assert_redirected_to mural_path(anchor: "mural")
  end

  private

  def activity_event
    ActivityEvent.create!(
      event_type: "leader_changed",
      user: user,
      match: match_record,
      message: "Ana assumiu a lideranca.",
      dedupe_key: SecureRandom.uuid
    )
  end
end
