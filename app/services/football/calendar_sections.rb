module Football
  class CalendarSections
    def initialize(matches)
      @matches = matches
    end

    def call
      group_sections + knockout_sections
    end

    private

    attr_reader :matches

    def group_sections
      matches
        .select { |match| match.group_name.present? }
        .group_by(&:group_name)
        .sort_by { |group_name, _matches| group_name.to_s }
        .map do |group_name, group_matches|
          {
            title: group_name,
            kicker: "Fase de grupos",
            rounds: group_matches.group_by { |match| round_label(match) }.sort_by { |label, _| round_sort_key(label) }
          }
        end
    end

    def knockout_sections
      matches
        .select { |match| match.group_name.blank? }
        .group_by { |match| knockout_label(match) }
        .sort_by { |label, _matches| Bracket::ROUND_SORT.fetch(label, 99) }
        .map do |label, knockout_matches|
          {
            title: label,
            kicker: "Mata-mata",
            rounds: [[ label, knockout_matches.sort_by(&:kickoff_at) ]]
          }
        end
    end

    def round_label(match)
      return "Rodada #{match.round_number}" if match.round_number.present?

      "Rodada"
    end

    def round_sort_key(label)
      label.to_s[/\d+/].to_i
    end

    def knockout_label(match)
      Bracket.round_label(match.round_name.presence || match.stage.presence || "Mata-mata")
    end
  end
end
