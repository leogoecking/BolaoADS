class LocalizeTeamNames < ActiveRecord::Migration[8.0]
  TRANSLATIONS = {
    "Algeria" => "Argélia",
    "Argelia" => "Argélia",
    "Australia" => "Austrália",
    "Austria" => "Áustria",
    "Belgium" => "Bélgica",
    "Belgica" => "Bélgica",
    "Bosnia & Herzegovina" => "Bósnia e Herzegovina",
    "Brazil" => "Brasil",
    "Canada" => "Canadá",
    "Colombia" => "Colômbia",
    "Croatia" => "Croácia",
    "Croacia" => "Croácia",
    "Curaçao" => "Curaçao",
    "Côte d'Ivoire" => "Costa do Marfim",
    "Czechia" => "Tchéquia",
    "DR Congo" => "RD Congo",
    "Ecuador" => "Equador",
    "Egypt" => "Egito",
    "England" => "Inglaterra",
    "France" => "França",
    "Franca" => "França",
    "Germany" => "Alemanha",
    "Ghana" => "Gana",
    "Haiti" => "Haiti",
    "Iran" => "Irã",
    "Ira" => "Irã",
    "Iraq" => "Iraque",
    "Japan" => "Japão",
    "Jordan" => "Jordânia",
    "Jordania" => "Jordânia",
    "Mexico" => "México",
    "Morocco" => "Marrocos",
    "Netherlands" => "Países Baixos",
    "New Zealand" => "Nova Zelândia",
    "Nova Zelandia" => "Nova Zelândia",
    "Norway" => "Noruega",
    "Panama" => "Panamá",
    "Paraguay" => "Paraguai",
    "Qatar" => "Catar",
    "Saudi Arabia" => "Arábia Saudita",
    "Arabia Saudita" => "Arábia Saudita",
    "Scotland" => "Escócia",
    "Senegal" => "Senegal",
    "South Africa" => "África do Sul",
    "South Korea" => "Coreia do Sul",
    "Spain" => "Espanha",
    "Sweden" => "Suécia",
    "Switzerland" => "Suíça",
    "Tunisia" => "Tunísia",
    "Türkiye" => "Turquia",
    "USA" => "Estados Unidos",
    "Uruguay" => "Uruguai",
    "Uzbekistan" => "Uzbequistão",
    "Uzbequistao" => "Uzbequistão"
  }.freeze

  class MigrationTeam < ActiveRecord::Base
    self.table_name = "teams"
  end

  class MigrationMatch < ActiveRecord::Base
    self.table_name = "matches"
  end

  def up
    TRANSLATIONS.each do |current_name, localized_name|
      MigrationTeam.where(name: current_name).find_each do |team|
        localize_team(team, localized_name)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def localize_team(team, localized_name)
    existing = MigrationTeam.find_by(name: localized_name)
    if existing && existing.id != team.id
      preferred = preferred_team(team, existing)
      duplicate = duplicate_team(team, existing)
      merge_teams(preferred, duplicate)
      team = preferred
    end

    team.reload
    team.update!(name: localized_name) if team.persisted? && team.name != localized_name
  end

  def preferred_team(first, second)
    return first if first.code.to_s.start_with?("BSD-")
    return second if second.code.to_s.start_with?("BSD-")

    first
  end

  def duplicate_team(first, second)
    preferred = preferred_team(first, second)
    preferred.id == first.id ? second : first
  end

  def merge_teams(preferred, duplicate)
    MigrationMatch.where(home_team_id: duplicate.id).update_all(home_team_id: preferred.id)
    MigrationMatch.where(away_team_id: duplicate.id).update_all(away_team_id: preferred.id)
    MigrationMatch.where(underdog_team_id: duplicate.id).update_all(underdog_team_id: preferred.id)
    duplicate.destroy!
  end
end
