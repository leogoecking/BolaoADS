class MatchMessagesController < ApplicationController
  before_action :require_authentication
  before_action :set_match

  def index
    render partial: "matches/chat_messages", locals: { messages: @match.recent_match_messages }
  end

  def create
    @message = @match.match_messages.new(message_params.merge(user: current_user))

    if @message.save
      return render(partial: "matches/chat_messages", locals: { messages: @match.recent_match_messages }, status: :created) if request.xhr?

      redirect_to match_path(@match, anchor: "resenha"), notice: "Mensagem enviada."
    else
      return render(plain: @message.errors.full_messages.to_sentence, status: :unprocessable_entity) if request.xhr?

      redirect_to match_path(@match, anchor: "resenha"), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_match
    @match = Match.find(params[:match_id])
  end

  def message_params
    params.require(:match_message).permit(:body)
  end
end
