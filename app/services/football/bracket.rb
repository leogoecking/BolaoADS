module Football
  class Bracket
    ROUND_LABELS = {
      "Round of 32" => "16 avos",
      "Round of 16" => "Oitavas",
      "Quarterfinals" => "Quartas",
      "Semifinals" => "Semifinais",
      "Final" => "Final",
      "Match for 3rd place" => "3o lugar"
    }.freeze

    ROUND_ORDER = [
      "16 avos",
      "Oitavas",
      "Quartas",
      "Semifinais",
      "Final",
      "3o lugar",
      "Mata-mata"
    ].freeze

    ROUND_SORT = ROUND_ORDER.each_with_index.to_h.freeze

    def self.round_label(raw_label)
      ROUND_LABELS.fetch(raw_label.to_s, raw_label.to_s.presence || "Mata-mata")
    end

    def initialize(matches)
      @matches = matches
    end

    def call
      ROUND_ORDER.filter_map do |label|
        round_matches = grouped.fetch(label, [])
        next if round_matches.empty?

        { label: label, matches: round_matches.sort_by(&:kickoff_at) }
      end
    end

    private

    attr_reader :matches

    def grouped
      @grouped ||= matches
        .select { |match| match.group_name.blank? }
        .group_by { |match| self.class.round_label(match.round_name.presence || match.stage) }
    end
  end
end
