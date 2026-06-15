require "net/http"
require "json"

module Football
  class ApiClient
    ApiError = Class.new(StandardError)
    DEFAULT_BASE_URL = "https://sports.bzzoiro.com/api/v2/"
    DEFAULT_MATCHES_PATH = "events/?league_id=27&season_id=188&limit=200"
    DEFAULT_LIVE_PATH = "events/live/?league_id=27&season_id=188"

    def initialize(
      base_url: ENV["FOOTBALL_API_BASE_URL"].presence || DEFAULT_BASE_URL,
      matches_path: ENV["FOOTBALL_API_MATCHES_PATH"].presence || DEFAULT_MATCHES_PATH,
      live_path: ENV["FOOTBALL_API_LIVE_PATH"].presence || DEFAULT_LIVE_PATH,
      api_key: ENV["FOOTBALL_API_KEY"]
    )
      @base_url = base_url
      @matches_path = matches_path
      @live_path = live_path
      @api_key = api_key.to_s.gsub(/\s+/, "")
    end

    def matches
      payloads = []
      path = matches_path

      loop do
        payload = get_json(path)
        payloads.concat(Array(payload["results"] || payload["matches"] || payload["data"] || payload["events"] || payload))
        path = payload["next"]
        break if path.blank?
      end

      payloads
    end

    def live_matches
      payload = get_json(live_path)
      Array(payload["results"] || payload["matches"] || payload["data"] || payload["events"] || payload)
    end

    def incidents(event_id)
      payload = get_json("events/#{event_id}/incidents/")
      Array(payload["incidents"] || payload["results"] || payload["data"])
    end

    def stats(event_id)
      get_json("events/#{event_id}/stats/")
    end

    def venue(venue_id)
      get_json("venues/#{venue_id}/")
    end

    def group_standings
      get_json(ENV.fetch("FOOTBALL_API_STANDINGS_PATH", "leagues/27/standings/?season_id=188"))
    end

    private

    attr_reader :base_url, :matches_path, :live_path, :api_key

    def get_json(path)
      raise ApiError, "FOOTBALL_API_KEY nao configurada" if api_key.blank?

      uri = URI.join(base_url, path)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Token #{api_key}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 20) do |http|
        http.request(request)
      end

      raise ApiError, "API retornou HTTP #{response.code}: #{response.body.truncate(160)}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => error
      raise ApiError, "Resposta JSON invalida: #{error.message}"
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout => error
      raise ApiError, "Falha de conexao com a API: #{error.message}"
    end
  end

end
