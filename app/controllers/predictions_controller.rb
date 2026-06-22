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
      redirect_to prediction_return_path, notice: "Palpite salvo."
    elsif params[:return_to].present?
      redirect_to prediction_return_path, alert: @prediction.errors.full_messages.to_sentence
    else
      prepare_match_show
      render "matches/show", status: :unprocessable_entity
    end
  end

  def prediction_return_path
    url_from(params[:return_to]) || matches_path
  end

  def prepare_match_show
    @live_stats = Football::LiveMatchStats.new(@match).call if @match.live? || @match.finished?
    @match_messages = @match.recent_match_messages
    @match_message = MatchMessage.new
  end
end
