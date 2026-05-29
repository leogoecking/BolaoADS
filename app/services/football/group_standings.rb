module Football
  class GroupStandings
    CACHE_KEY = "football/world-cup-2026/group-standings"

    def initialize(client: ApiClient.new)
      @client = client
    end

    def call
      Rails.cache.fetch(CACHE_KEY, expires_in: 5.minutes) do
        normalize(client.group_standings)
      end
    rescue ApiClient::ApiError => error
      Rails.logger.warn("[football_api] standings: #{error.message}")
      {}
    end

    private

    attr_reader :client

    def normalize(payload)
      groups = payload.fetch("groups", {})

      groups.each_with_object({}) do |(group_name, rows), standings|
        standings[group_name] = Array(rows).map do |row|
          {
            position: row["position"],
            team_id: row["team_id"],
            team_name: row["team_name"],
            played: row["played"],
            won: row["won"],
            drawn: row["drawn"],
            lost: row["lost"],
            goals_for: row["gf"],
            goals_against: row["ga"],
            goal_difference: row["gd"],
            points: row["pts"],
            live: row["live"]
          }
        end
      end
    end
  end
end
