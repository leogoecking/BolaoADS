class PredictionCommentsController < ApplicationController
  before_action :require_authentication
  before_action :set_prediction

  def create
    @comment = @prediction.prediction_comments.new(comment_params.merge(user: current_user))

    if @comment.save
      redirect_to matches_path(anchor: "mural"), notice: "Comentario publicado."
    else
      redirect_to matches_path(anchor: "mural"), alert: @comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_prediction
    @prediction = Prediction.includes(:match).find(params[:prediction_id])
  end

  def comment_params
    params.require(:prediction_comment).permit(:body)
  end
end
