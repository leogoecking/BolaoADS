class SpecialPredictionsController < ApplicationController
  before_action :require_authentication
  before_action :set_question, only: %i[create update]

  def index
    @questions = SpecialQuestion.ordered
    @predictions_by_question_id = current_user.special_predictions.index_by(&:special_question_id)
  end

  def create
    @prediction = current_user.special_predictions.new(special_prediction_params.merge(special_question: @question))
    save_prediction
  end

  def update
    @prediction = current_user.special_predictions.find_by!(special_question: @question)
    @prediction.assign_attributes(special_prediction_params)
    save_prediction
  end

  private

  def set_question
    @question = SpecialQuestion.find(params[:special_question_id])
  end

  def special_prediction_params
    params.require(:special_prediction).permit(:answer)
  end

  def save_prediction
    if @prediction.save
      redirect_to special_predictions_path, notice: "Palpite especial salvo."
    else
      @questions = SpecialQuestion.ordered
      @predictions_by_question_id = current_user.special_predictions.index_by(&:special_question_id)
      render :index, status: :unprocessable_entity
    end
  end
end
