class MatchesController < ApplicationController
  before_action :require_authentication

  def index
    @matches = Match.ordered
    @predictions_by_match_id = current_user.predictions.index_by(&:match_id)
  end

  def show
    @match = Match.includes(:home_team, :away_team).find(params[:id])
    @prediction = current_user.predictions.find_or_initialize_by(match: @match)
    @revealed_predictions = @match.predictions.includes(:user).order("users.name") if @match.predictions_revealed?
  end
end
