module ApplicationHelper
  BSD_TEAM_CODE_PATTERN = /\ABSD-(\d+)\z/
  ACHIEVEMENT_ICONS = {
    "mae_dina" => "🔮",
    "cacador_de_zebra" => "🦓",
    "zicador" => "⛈️",
    "pe_quente" => "🔥",
    "geladeira" => "🧊",
    "sniper" => "🎯",
    "ultima_hora" => "⏱️",
    "maratonista_grupos" => "🏃",
    "nao_dormiu_no_ponto" => "📅",
    "cheirinho_lideranca" => "📈",
    "all_in_consciente" => "🪙",
    "so_passou_raiva" => "😤",
    "sobreviveu_mata_mata" => "🏆",
    "magnata_do_palpite" => "💰",
    "milionario_de_mentira" => "💎"
  }.freeze

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

  def achievement_icon(achievement_or_key)
    key = achievement_or_key.respond_to?(:key) ? achievement_or_key.key : achievement_or_key.to_s

    ACHIEVEMENT_ICONS.fetch(key, "🏅")
  end
end
