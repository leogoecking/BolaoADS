require "test_helper"

class AchievementsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    get achievements_path

    assert_redirected_to new_session_path
  end

  test "shows achievements as cards with unlocked state" do
    player = user
    Achievement.ensure_catalog!
    achievement = Achievement.find_by!(key: "mae_dina")
    UserAchievement.create!(user: player, achievement: achievement, unlocked_at: Time.zone.local(2026, 6, 20, 12, 0, 0))

    post session_path, params: { email: player.email, password: "secret123" }
    get achievements_path

    assert_response :success
    assert_includes response.body, "achievement-card"
    assert_includes response.body, "achievement-card-unlocked"
    assert_includes response.body, "Mae Dina"
    assert_includes response.body, "Liberada em"
    assert_includes response.body, "Bloqueada"
  end
end
