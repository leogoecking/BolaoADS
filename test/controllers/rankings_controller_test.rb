require "test_helper"

class RankingsControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    get ranking_path

    assert_redirected_to new_session_path
  end

  test "shows compact unlocked achievements on ranking" do
    player = user
    Achievement.ensure_catalog!
    Achievement.order(:id).first(4).each_with_index do |achievement, index|
      UserAchievement.create!(
        user: player,
        achievement: achievement,
        unlocked_at: Time.zone.local(2026, 6, 20, 12, index, 0)
      )
    end

    post session_path, params: { email: player.email, password: "secret123" }
    get ranking_path

    assert_response :success
    assert_includes response.body, "Conquistas"
    assert_includes response.body, "ranking-achievements"
    assert_includes response.body, "ranking-achievement-icon"
    assert_includes response.body, "ranking-achievement-more"
    assert_includes response.body, "+1"
  end

  test "highlights adcoins leader on ranking" do
    player = user
    rich = user(name: "Rico", email: "rico@example.com")
    player.update!(adcoins_balance: 100)
    rich.update!(adcoins_balance: 1_000)

    post session_path, params: { email: player.email, password: "secret123" }
    get ranking_path

    assert_response :success
    assert_includes response.body, "adcoins-leader-pill"
    assert_includes response.body, "1000 🪙"
  end

  test "shows empty achievement state on ranking" do
    player = user

    post session_path, params: { email: player.email, password: "secret123" }
    get ranking_path

    assert_response :success
    assert_includes response.body, "Nenhuma"
  end
end
