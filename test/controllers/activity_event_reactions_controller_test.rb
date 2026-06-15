require "test_helper"

class ActivityEventReactionsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    event = activity_event

    post activity_event_reaction_path(event, reaction_type: "kkkk")

    assert_redirected_to new_session_path
  end

  test "creates reaction once" do
    player = user(name: "Bia", email: "bia@example.com")
    event = activity_event

    post session_path, params: { email: player.email, password: "secret123" }

    assert_difference "ActivityEventReaction.count", 1 do
      post activity_event_reaction_path(event, reaction_type: "kkkk")
    end

    assert_no_difference "ActivityEventReaction.count" do
      post activity_event_reaction_path(event, reaction_type: "kkkk")
    end

    assert_redirected_to mural_path(anchor: "mural")
  end

  test "removes current user reaction" do
    player = user(name: "Bia", email: "bia@example.com")
    other = user(name: "Caio", email: "caio@example.com")
    event = activity_event
    ActivityEventReaction.create!(user: player, activity_event: event, reaction_type: "zicou")
    ActivityEventReaction.create!(user: other, activity_event: event, reaction_type: "zicou")

    post session_path, params: { email: player.email, password: "secret123" }

    assert_difference "ActivityEventReaction.count", -1 do
      delete activity_event_reaction_path(event, reaction_type: "zicou")
    end

    assert ActivityEventReaction.exists?(user: other, activity_event: event, reaction_type: "zicou")
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
