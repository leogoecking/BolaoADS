class MatchesController < ApplicationController
  before_action :require_authentication

  def index
    @matches = Match.ordered.to_a
    @today_matches = @matches.select { |match| match.kickoff_at.to_date == Date.current }
    @highlight_matches = @matches
      .select { |match| match.kickoff_at.to_date > Date.current }
      .first(6)
    @predictions_by_match_id = current_user.predictions.index_by(&:match_id)
  end

  def calendar
    @calendar_period = params[:period].to_s
    @calendar_period = "upcoming" unless Football::CalendarSections::PERIODS.include?(@calendar_period)
    @calendar_sections = Football::CalendarSections.new(Match.ordered.to_a, period: @calendar_period).call
    @predictions_by_match_id = current_user.predictions.index_by(&:match_id)
    @calendar_predictions_by_match_id = calendar_revealed_predictions_by_match_id
  end

  def groups
    @group_standings = Football::GroupStandings.new.call
  end

  def bracket
    @bracket_rounds = Football::Bracket.new(Match.ordered.to_a).call
    @predictions_by_match_id = current_user.predictions.index_by(&:match_id)
  end

  def live_sync
    result = Football::LiveScoreSync.call

    render json: {
      ok: true,
      synced_count: result.fetch(:synced_count),
      changed_count: result.fetch(:changed_count),
      skipped: result.fetch(:skipped),
      last_synced_at: result.fetch(:last_synced_at)&.iso8601,
      has_live_matches: Match.where(status: "live").exists?
    }
  rescue Football::ApiClient::ApiError => error
    render json: { ok: false, error: error.message }, status: :bad_gateway
  end

  def show
    @match = Match.includes(:home_team, :away_team).find(params[:id])
    @prediction = current_user.predictions.find_or_initialize_by(match: @match)
    @revealed_predictions = @match.predictions.includes(:user).order("users.name") if @match.predictions_revealed?
    @live_stats = Football::LiveMatchStats.new(@match).call if @match.live? || @match.finished?
    @match_messages = @match.recent_match_messages
    @match_message = MatchMessage.new
  end

  private

  def calendar_revealed_predictions_by_match_id
    return {} unless @calendar_period == "finished"

    match_ids = @calendar_sections
      .flat_map { |section| section.fetch(:matches) }
      .select(&:predictions_revealed?)
      .map(&:id)

    return {} if match_ids.empty?

    Prediction
      .includes(:user)
      .joins(:user)
      .where(match_id: match_ids)
      .order(Arel.sql("predictions.points DESC, users.name ASC"))
      .group_by(&:match_id)
  end
end
