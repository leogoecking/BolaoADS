module Football
  class ClientFactory
    def self.build
      case ENV.fetch("FOOTBALL_API_PROVIDER", "bsd")
      when "api_football", "api-football", "apisports"
        ApiFootballClient.new
      else
        ApiClient.new
      end
    end
  end
end
