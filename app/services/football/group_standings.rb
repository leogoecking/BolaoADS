module Football
  class GroupStandings
    CACHE_KEY = "football/world-cup-2026/group-standings-v4"

    def initialize(client: ApiClient.new)
      @client = client
    end

    def call
      Rails.cache.fetch(CACHE_KEY, expires_in: 5.minutes) do
        with_local_fallback(normalize(client.group_standings))
      end
    rescue ApiClient::ApiError => error
      Rails.logger.warn("[football_api] standings: #{error.message}")
      sorted_standings(local_standings)
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
            team_name: localized_team_name(row["team_name"]),
            played: row["played"],
            won: row["won"],
            drawn: row["drawn"],
            lost: row["lost"],
            goals_for: row["gf"],
            goals_against: row["ga"],
            goal_difference: row["gd"],
            points: row["pts"],
            xgf: row["xgf"],
            xga: row["xga"],
            xgd: row["xgd"],
            xg_games: row["xg_games"],
            live: row["live"]
          }
        end
      end
    end

    def with_local_fallback(remote_standings)
      local_standings.each do |group_name, rows|
        remote_standings[group_name] = complete_group_rows(remote_standings[group_name], rows)
      end

      sorted_standings(remote_standings)
    end

    def sorted_standings(standings)
      standings.sort.to_h
    end

    def complete_group_rows(remote_rows, local_rows)
      return local_rows if remote_rows.blank?

      normalized_remote_rows = Array(remote_rows).map { |row| merge_local_identity(row, local_rows) }
      remote_identities = normalized_remote_rows.flat_map { |row| row_identities(row) }
      local_only_rows = local_rows.reject { |local_row| row_identities(local_row).any? { |identity| remote_identities.include?(identity) } }
        .map { |local_row| local_row.merge(position: nil) }

      (normalized_remote_rows + local_only_rows)
        .sort_by { |row| [ row[:position].presence || 99, -row[:points].to_i, row[:team_name].to_s ] }
        .each_with_index.map { |row, index| row.merge(position: index + 1) }
    end

    def merge_local_identity(remote_row, local_rows)
      local_row = local_rows.find { |row| (row_identities(row) & row_identities(remote_row)).any? }
      return remote_row if local_row.blank?

      remote_row.merge(
        team_id: local_row[:team_id].presence || remote_row[:team_id],
        team_name: remote_row[:team_name].presence || local_row[:team_name]
      )
    end

    def row_identities(row)
      [
        row[:team_id].presence,
        localized_team_name(row[:team_name]).parameterize.presence
      ].compact
    end

    def localized_team_name(name)
      MatchSynchronizer::TEAM_NAME_TRANSLATIONS.fetch(name.to_s, name.to_s)
    end

    def local_standings
      Match
        .includes(:home_team, :away_team)
        .where.not(group_name: [ nil, "" ])
        .order(:group_name, :kickoff_at, :id)
        .select { |match| world_cup_group?(match.group_name) }
        .group_by(&:group_name)
        .transform_values { |matches| local_rows(matches) }
    end

    def world_cup_group?(group_name)
      group_name.to_s.match?(/\AGroup [A-L]\z/)
    end

    def local_rows(matches)
      rows_by_team = {}

      matches.each do |match|
        [ match.home_team, match.away_team ].each { |team| rows_by_team[team.id] ||= local_row(team) }
      end

      rows_by_team.values
        .each_with_index.map { |row, index| row.merge(position: index + 1) }
    end

    def local_row(team)
      {
        position: nil,
        team_id: bsd_team_id(team),
        team_name: team.name,
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        goals_for: 0,
        goals_against: 0,
        goal_difference: 0,
        points: 0,
        live: false
      }
    end

    def bsd_team_id(team)
      team.code.to_s[/\ABSD-(\d+)\z/, 1]&.to_i
    end
  end
end
