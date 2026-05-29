module ApplicationHelper
  BSD_TEAM_CODE_PATTERN = /\ABSD-(\d+)\z/

  def team_logo_url(team)
    bsd_team_id = team.code.to_s[BSD_TEAM_CODE_PATTERN, 1]
    return if bsd_team_id.blank?

    bsd_team_logo_url(bsd_team_id)
  end

  def bsd_team_logo_url(team_id)
    return if team_id.blank?

    "https://sports.bzzoiro.com/img/team/#{team_id}/"
  end

  def team_initials(team)
    team.name.to_s
      .split
      .first(2)
      .map { |part| part.first&.upcase }
      .join
      .presence || "?"
  end
end
