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
      "3o lugar"
    ].freeze

    ROUND_SORT = ROUND_ORDER.each_with_index.to_h.freeze

    def self.round_label(raw_label)
      label = raw_label.to_s
      ROUND_LABELS[label] || (ROUND_ORDER.include?(label) ? label : nil)
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
        .each_with_object(Hash.new { |groups, label| groups[label] = [] }) do |match, groups|
          label = self.class.round_label(match.round_name.presence || match.stage)
          next if label.blank?

          groups[label] << match
        end
    end
  end
end
