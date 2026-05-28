module Football
  class MatchSynchronizer
    STATUS_MAP = {
      "timed" => "scheduled",
      "scheduled" => "scheduled",
      "not_started" => "scheduled",
      "live" => "live",
      "in_play" => "live",
      "paused" => "live",
      "finished" => "finished",
      "full_time" => "finished",
      "postponed" => "postponed"
    }.freeze

    def initialize(client: ApiClient.new)
      @client = client
    end

    def call
      client.matches.each { |payload| upsert_match(payload) }
    rescue ApiClient::ApiError => error
      Rails.logger.warn("[football_api] #{error.message}")
    end

    private

    attr_reader :client

    def upsert_match(payload)
      home_team = find_or_create_team(team_payload(payload, "home"))
      away_team = find_or_create_team(team_payload(payload, "away"))
      match = Match.find_or_initialize_by(external_id: external_id(payload))

      match.assign_attributes(
        home_team: home_team,
        away_team: away_team,
        kickoff_at: kickoff_at(payload),
        status: status(payload),
        home_score: score(payload, "home"),
        away_score: score(payload, "away"),
        stage: payload["stage"] || payload["round"],
        group_name: payload["group"] || payload["group_name"],
        last_synced_at: Time.current
      )

      match.save!
    end

    def find_or_create_team(payload)
      Team.find_or_create_by!(code: payload.fetch(:code)) do |team|
        team.name = payload.fetch(:name)
      end
    end

    def team_payload(payload, side)
      camel_side = "#{side}Team"
      team = payload["#{side}_team"] || payload[side] || payload[camel_side] || {}
      name = team["name"] || payload["#{side}_team_name"] || side.titleize
      code = team["code"] || team["tla"] || team["short_name"] || name.parameterize.upcase.first(12)

      { name: name, code: code }
    end

    def external_id(payload)
      (payload["id"] || payload["external_id"] || payload["match_id"] || fallback_external_id(payload)).to_s
    end

    def kickoff_at(payload)
      raw = payload["kickoff_at"] || payload["start_time"] || payload["utcDate"] || payload["date"]
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

    def fallback_external_id(payload)
      kickoff_token = kickoff_at(payload)&.to_i || Time.current.to_i
      "#{team_payload(payload, "home").fetch(:code)}-#{team_payload(payload, "away").fetch(:code)}-#{kickoff_token}"
    end
  end
end
