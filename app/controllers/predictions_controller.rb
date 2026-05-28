class PredictionsController < ApplicationController
  before_action :require_authentication
  before_action :set_match

  def create
    @prediction = current_user.predictions.new(prediction_params.merge(match: @match))
    save_prediction
  end

  def update
    @prediction = current_user.predictions.find_by!(match: @match)
    @prediction.assign_attributes(prediction_params)
    save_prediction
  end

  private

  def set_match
    @match = Match.find(params[:match_id])
  end

  def prediction_params
    params.require(:prediction).permit(:home_score, :away_score, :adcoins_wager)
  end

  def save_prediction
    if @prediction.save
      redirect_to matches_path, notice: "Palpite salvo."
    else
      render "matches/show", status: :unprocessable_entity
    end
  end
end
