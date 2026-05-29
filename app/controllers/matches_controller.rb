class MatchesController < ApplicationController
  before_action :require_authentication

  def index
    @matches = Match.ordered.to_a
    @today_matches = @matches.select { |match| match.kickoff_at.to_date == Date.current }
    @upcoming_matches_by_date = @matches
      .select { |match| match.kickoff_at.to_date > Date.current }
      .group_by { |match| match.kickoff_at.to_date }
    @past_matches = @matches.select { |match| match.kickoff_at.to_date < Date.current }.reverse
    @group_standings = Football::GroupStandings.new.call
    @predictions_by_match_id = current_user.predictions.index_by(&:match_id)
  end

  def show
    @match = Match.includes(:home_team, :away_team).find(params[:id])
    @prediction = current_user.predictions.find_or_initialize_by(match: @match)
    @revealed_predictions = @match.predictions.includes(:user).order("users.name") if @match.predictions_revealed?
  end
end
