module Football
  class CalendarSections
    PERIODS = %w[today upcoming finished].freeze

    def initialize(matches, period: "upcoming")
      @matches = matches
      @period = PERIODS.include?(period.to_s) ? period.to_s : "upcoming"
    end

    def call
      return today_sections if period == "today"
      return finished_sections if period == "finished"

      upcoming_sections
    end

    private

    attr_reader :matches, :period

    def today_sections
      date_sections(matches.select { |match| match.kickoff_at.to_date == Date.current }, kicker: "Hoje")
    end

    def upcoming_sections
      date_sections(matches.reject(&:finished?), kicker: "Agenda")
    end

    def finished_sections
      date_sections(matches.select(&:finished?), kicker: "Encerrados", direction: :desc)
    end

    def date_sections(section_matches, kicker:, direction: :asc)
      grouped_sections = section_matches
        .group_by { |match| match.kickoff_at.to_date }
        .sort_by { |date, _date_matches| date }

      grouped_sections.reverse! if direction == :desc

      grouped_sections.map do |date, date_matches|
        {
          title: I18n.l(date, format: "%A, %d/%m"),
          kicker: kicker,
          matches: date_matches.sort_by(&:kickoff_at)
        }
      end
    end
  end
end
