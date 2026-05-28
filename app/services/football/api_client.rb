require "net/http"
require "json"

module Football
  class ApiClient
    ApiError = Class.new(StandardError)

    def initialize(
      base_url: ENV.fetch("FOOTBALL_API_BASE_URL", "https://api.sportdb.dev"),
      matches_path: ENV.fetch("FOOTBALL_API_MATCHES_PATH", "/api/football/live"),
      api_key: ENV["FOOTBALL_API_KEY"]
    )
      @base_url = base_url
      @matches_path = matches_path
      @api_key = api_key
    end

    def matches
      payload = get_json(matches_path)
      Array(payload["matches"] || payload["data"] || payload["events"] || payload)
    end

    private

    attr_reader :base_url, :matches_path, :api_key

    def get_json(path)
      uri = URI.join(base_url, path)
      request = Net::HTTP::Get.new(uri)
      request["X-API-Key"] = api_key if api_key.present?

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      raise ApiError, "API retornou HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => error
      raise ApiError, "Resposta JSON invalida: #{error.message}"
    end
  end
end
