module Football
  class MatchSynchronizer
    STATUS_MAP = {
      "timed" => "scheduled",
      "scheduled" => "scheduled",
      "not_started" => "scheduled",
      "notstarted" => "scheduled",
      "live" => "live",
      "in_play" => "live",
      "inprogress" => "live",
      "penalties" => "live",
      "paused" => "live",
      "finished" => "finished",
      "full_time" => "finished",
      "postponed" => "postponed",
      "cancelled" => "postponed"
    }.freeze

    TEAM_NAME_TRANSLATIONS = {
      "Algeria" => "Argélia",
      "Australia" => "Austrália",
      "Austria" => "Áustria",
      "Belgium" => "Bélgica",
      "Bosnia & Herzegovina" => "Bósnia e Herzegovina",
      "Brazil" => "Brasil",
      "Canada" => "Canadá",
      "Colombia" => "Colômbia",
      "Croatia" => "Croácia",
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
      "Iraq" => "Iraque",
      "Japan" => "Japão",
      "Jordan" => "Jordânia",
      "Mexico" => "México",
      "Morocco" => "Marrocos",
      "Netherlands" => "Países Baixos",
      "New Zealand" => "Nova Zelândia",
      "Norway" => "Noruega",
      "Panama" => "Panamá",
      "Paraguay" => "Paraguai",
      "Qatar" => "Catar",
      "Saudi Arabia" => "Arábia Saudita",
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
      "Uzbekistan" => "Uzbequistão"
    }.freeze

    def initialize(client: ClientFactory.build, live_only: false)
      @client = client
      @live_only = live_only
    end

    def call
      payloads.sum do |payload|
        upsert_match(payload)
        1
      end
    end

    private

    attr_reader :client, :live_only

    def payloads
      return client.live_matches if live_only && client.respond_to?(:live_matches)

      client.matches
    end

    def upsert_match(payload)
      home_team = find_or_create_team(team_payload(payload, "home"))
      away_team = find_or_create_team(team_payload(payload, "away"))
      kickoff = kickoff_at(payload)
      match = find_match(payload, home_team, away_team, kickoff)

      match.assign_attributes(
        home_team: home_team,
        away_team: away_team,
        kickoff_at: kickoff,
        status: status(payload),
        home_score: score(payload, "home"),
        away_score: score(payload, "away"),
        current_minute: current_minute(payload),
        period: period(payload),
        stage: payload["stage"] || payload["round"],
        group_name: payload["group"] || payload["group_name"],
        last_synced_at: Time.current
      )

      match.save!
      sync_incidents(match, payload) if live_only
    end

    def find_match(payload, home_team, away_team, kickoff)
      existing = Match.find_by(external_id: external_id(payload))
      return existing if existing

      Match
        .where(home_team: home_team, away_team: away_team)
        .where(kickoff_at: (kickoff - 6.hours)..(kickoff + 6.hours))
        .first || Match.new(external_id: external_id(payload))
    end

    def find_or_create_team(payload)
      team = Team.find_by(code: payload.fetch(:code)) || Team.find_by(name: payload.fetch(:name))
      if team
        team.update!(name: payload.fetch(:name)) if team.name != payload.fetch(:name)
        team
      else
        Team.create!(code: payload.fetch(:code)) do |new_team|
          new_team.name = payload.fetch(:name)
        end
      end
    end

    def team_payload(payload, side)
      camel_side = "#{side}Team"
      team = payload["#{side}_team"] || payload[side] || payload[camel_side] || {}
      name = team["name"] || payload["#{side}_team"] || payload["#{side}_team_name"] || side.titleize
      code = team["code"] || team["tla"] || team["short_name"] || external_team_code(payload, side) || name.parameterize.upcase.first(12)

      { name: localized_team_name(name), code: code }
    end

    def localized_team_name(name)
      TEAM_NAME_TRANSLATIONS.fetch(name.to_s, name.to_s)
    end

    def external_team_code(payload, side)
      external_id = payload["#{side}_team_id"]
      "BSD-#{external_id}" if external_id.present?
    end

    def external_id(payload)
      (payload["id"] || payload["external_id"] || payload["match_id"] || fallback_external_id(payload)).to_s
    end

    def kickoff_at(payload)
      raw = payload["kickoff_at"] || payload["event_date"] || payload["start_time"] || payload["utcDate"] || payload["date"]
      Time.zone.parse(raw.to_s)
    end

    def status(payload)
      raw = payload["status"].to_s.downcase
      STATUS_MAP.fetch(raw, "scheduled")
    end

    def score(payload, side)
      payload.dig("score", side).presence ||
        payload["#{side}_score"].presence ||
        payload.dig("scores", side).presence ||
        payload.dig("score", "fullTime", side)
    end

    def current_minute(payload)
      payload["current_minute"] || payload["minute"] || payload.dig("time", "minute")
    end

    def period(payload)
      payload["period"] || payload.dig("time", "period")
    end

    def sync_incidents(match, payload)
      return unless client.respond_to?(:incidents)

      incidents = client.incidents(external_id(payload))
      match.update_columns(
        live_incidents: JSON.generate(incidents),
        live_incidents_synced_at: Time.current,
        updated_at: Time.current
      )
    rescue ApiClient::ApiError
      nil
    end

    def fallback_external_id(payload)
      kickoff_token = kickoff_at(payload)&.to_i || Time.current.to_i
      "#{team_payload(payload, "home").fetch(:code)}-#{team_payload(payload, "away").fetch(:code)}-#{kickoff_token}"
    end
  end
end
