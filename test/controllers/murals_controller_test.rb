require "test_helper"

class MuralsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    get mural_path

    assert_redirected_to new_session_path
  end

  test "shows mural to authenticated user" do
    player = user
    event = activity_event

    post session_path, params: { email: player.email, password: "secret123" }
    get mural_path

    assert_response :success
    assert_includes response.body, "Atividades do bolao"
    assert_includes response.body, event.message
  end

  private

  def activity_event
    ActivityEvent.create!(
      event_type: "leader_changed",
      user: user(name: "Bia", email: "bia@example.com"),
      match: match_record,
      message: "Bia assumiu a lideranca.",
      dedupe_key: SecureRandom.uuid
    )
  end
end
