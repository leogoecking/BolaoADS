require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "builds BSD team logo URL from team code" do
    team = Team.new(name: "Mexico", code: "BSD-451")

    assert_equal "https://sports.bzzoiro.com/img/team/451/", team_logo_url(team)
  end

  test "returns nil logo URL when team has no BSD code" do
    team = Team.new(name: "Brasil", code: "BRA")

    assert_nil team_logo_url(team)
  end

  test "builds team initials" do
    team = Team.new(name: "South Africa", code: "BSD-1")

    assert_equal "SA", team_initials(team)
  end
end
