module Football
  class LiveMatchStats
    STAT_ROWS = [
      [ "ball_possession", "Posse de bola", "%" ],
      [ "expected_goals", "Gols esperados", nil ],
      [ "total_shots", "Finalizacoes", nil ],
      [ "shots_on_target", "No alvo", nil ],
      [ "shots_off_target", "Para fora", nil ],
      [ "blocked_shots", "Bloqueadas", nil ],
      [ "passes", "Passes", nil ],
      [ "pass_accuracy_pct", "Precisao nos passes", "%" ],
      [ "final_third_entries", "Entradas no terco final", nil ],
      [ "dangerous_attack", "Ataques perigosos", nil ],
      [ "fouls", "Faltas", nil ],
      [ "goalkeeper_saves", "Defesas", nil ]
    ].freeze

    def initialize(match, client: nil)
      @match = match
      @client = client
      @default_client = client.nil?
    end

    def call
      return nil if default_client && Rails.env.test?
      return nil unless client.respond_to?(:stats)

      payload = client.stats(match.external_id)
      stats = payload["stats"] || {}
      home_stats = stats["home"] || {}
      away_stats = stats["away"] || {}
      rows = stat_rows(home_stats, away_stats)

      return nil if rows.empty?

      {
        event_id: payload["event_id"],
        rows: rows,
        shot_count: Array(payload["shotmap"]).size,
        momentum_count: Array(payload["momentum"]).size
      }
    rescue ApiClient::ApiError
      nil
    end

    private

    attr_reader :match, :client, :default_client

    def client
      @client ||= ClientFactory.build
    end

    def stat_rows(home_stats, away_stats)
      STAT_ROWS.filter_map do |key, label, unit|
        home_value = stat_value(home_stats, key)
        away_value = stat_value(away_stats, key)
        next if home_value.nil? && away_value.nil?

        {
          key: key,
          label: label,
          home: home_value,
          away: away_value,
          home_label: formatted_value(home_value, unit),
          away_label: formatted_value(away_value, unit),
          unit: unit
        }
      end
    end

    def stat_value(stats, key)
      value = stats[key]
      value = value["actual"] if value.is_a?(Hash) && value.key?("actual")
      return if value.nil?

      value.is_a?(Numeric) ? value : value.to_s
    end

    def formatted_value(value, unit)
      return "-" if value.nil?

      number = value.is_a?(Float) ? value.round(2) : value
      unit.present? ? "#{number}#{unit}" : number.to_s
    end
  end
end
