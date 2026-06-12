brasil = Team.find_or_create_by!(code: "BRA") { |team| team.name = "Brasil" }
argentina = Team.find_or_create_by!(code: "ARG") { |team| team.name = "Argentina" }
franca = Team.find_or_create_by!(code: "FRA") { |team| team.name = "Franca" }
alemanha = Team.find_or_create_by!(code: "ALE") { |team| team.name = "Alemanha" }

Match.find_or_create_by!(external_id: "seed-bra-arg") do |match|
  match.home_team = brasil
  match.away_team = argentina
  match.kickoff_at = 2.days.from_now
  match.status = "scheduled"
  match.stage = "Fase de grupos"
  match.group_name = "Grupo A"
  match.underdog_team = argentina
end

Match.find_or_create_by!(external_id: "seed-fra-ale") do |match|
  match.home_team = franca
  match.away_team = alemanha
  match.kickoff_at = 3.days.from_now
  match.status = "scheduled"
  match.stage = "Fase de grupos"
  match.group_name = "Grupo B"
  match.underdog_team = alemanha
end

Achievement.ensure_catalog!

special_closes_at = Time.zone.local(2026, 6, 18, 23, 59, 0)
[
  ["campeao", "Campeao", "text", 20],
  ["vice_campeao", "Vice-campeao", "text", 15],
  ["artilheiro", "Artilheiro", "text", 15],
  ["melhor_defesa", "Melhor defesa", "text", 15],
  ["selecao_decepcao", "Selecao decepcao", "text", 10],
  ["selecao_surpresa", "Selecao surpresa", "text", 10],
  ["fase_brasil", "Brasil chega ate qual fase?", "text", 10],
  ["gols_brasil", "Quantos gols o Brasil fara?", "number", 10],
  ["penaltis_final", "Tera disputa de penaltis na final?", "boolean", 10]
].each do |key, prompt, answer_type, points_value|
  SpecialQuestion.find_or_create_by!(key: key) do |question|
    question.prompt = prompt
    question.answer_type = answer_type
    question.points_value = points_value
    question.closes_at = special_closes_at
  end
end
