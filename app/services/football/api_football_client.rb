require "net/http"
require "json"

module Football
  class ApiFootballClient
    ApiError = ApiClient::ApiError

    STATUS_MAP = {
      "TBD" => "scheduled",
      "NS" => "scheduled",
      "1H" => "live",
      "HT" => "live",
      "2H" => "live",
      "ET" => "live",
      "BT" => "live",
      "P" => "live",
      "SUSP" => "live",
      "INT" => "live",
      "FT" => "finished",
      "AET" => "finished",
      "PEN" => "finished",
      "PST" => "postponed",
      "CANC" => "postponed",
      "ABD" => "postponed",
      "AWD" => "finished",
      "WO" => "finished"
    }.freeze

    def initialize(
      base_url: ENV.fetch("API_FOOTBALL_BASE_URL", "https://v3.football.api-sports.io/"),
      matches_path: ENV.fetch("API_FOOTBALL_MATCHES_PATH", "fixtures?league=1&season=2026"),
      live_path: ENV.fetch("API_FOOTBALL_LIVE_PATH", "fixtures?league=1&season=2026&live=all"),
      api_key: ENV["API_FOOTBALL_KEY"]
    )
      @base_url = base_url
      @matches_path = matches_path
      @live_path = live_path
      @api_key = api_key.to_s.gsub(/\s+/, "")
    end

    def matches
      response = get_json(matches_path)
      raise_api_errors!(response)
      Array(response["response"]).map { |payload| normalize_fixture(payload) }
    end

    def live_matches
      response = get_json(live_path)
      raise_api_errors!(response)
      Array(response["response"]).map { |payload| normalize_fixture(payload) }
    end

    private

    attr_reader :base_url, :matches_path, :live_path, :api_key

    def get_json(path)
      raise ApiError, "API_FOOTBALL_KEY nao configurada" if api_key.blank?

      uri = URI.join(base_url, path)
      request = Net::HTTP::Get.new(uri)
      request["x-apisports-key"] = api_key

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end

      raise ApiError, "API-FOOTBALL retornou HTTP #{response.code}: #{response.body.truncate(160)}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => error
      raise ApiError, "Resposta JSON invalida: #{error.message}"
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout => error
      raise ApiError, "Falha de conexao com a API-FOOTBALL: #{error.message}"
    end

    def raise_api_errors!(response)
      errors = response["errors"]
      return if errors.nil? || (errors.respond_to?(:empty?) && errors.empty?)

      raise ApiError, "API-FOOTBALL retornou erro: #{errors.inspect.truncate(160)}"
    end

    def normalize_fixture(payload)
      fixture = payload.fetch("fixture", {})
      teams = payload.fetch("teams", {})
      goals = payload.fetch("goals", {})
      league = payload.fetch("league", {})
      status = fixture.fetch("status", {})

      {
        "id" => "api-football-#{fixture["id"]}",
        "home_team_id" => teams.dig("home", "id"),
        "home_team" => teams.dig("home", "name"),
        "away_team_id" => teams.dig("away", "id"),
        "away_team" => teams.dig("away", "name"),
        "event_date" => fixture["date"],
        "status" => STATUS_MAP.fetch(status["short"].to_s, "scheduled"),
        "home_score" => goals["home"],
        "away_score" => goals["away"],
        "stage" => league["round"],
        "group" => league["round"]
      }
    end
  end
end
