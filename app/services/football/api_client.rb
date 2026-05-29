require "net/http"
require "json"

module Football
  class ApiClient
    ApiError = Class.new(StandardError)

    def initialize(
      base_url: ENV.fetch("FOOTBALL_API_BASE_URL", "https://sports.bzzoiro.com/api/v2/"),
      matches_path: ENV.fetch("FOOTBALL_API_MATCHES_PATH", "events/?league_id=27&season_id=188&limit=200"),
      api_key: ENV["FOOTBALL_API_KEY"]
    )
      @base_url = base_url
      @matches_path = matches_path
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

    def group_standings
      get_json(ENV.fetch("FOOTBALL_API_STANDINGS_PATH", "leagues/27/standings/?season_id=188"))
    end

    private

    attr_reader :base_url, :matches_path, :api_key

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
