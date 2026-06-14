class ActivityEventCommentsController < ApplicationController
  before_action :require_authentication
  before_action :set_activity_event

  def create
    @comment = @activity_event.activity_event_comments.new(comment_params.merge(user: current_user))

    if @comment.save
      redirect_to matches_path(anchor: "mural"), notice: "Resenha publicada."
    else
      redirect_to matches_path(anchor: "mural"), alert: @comment.errors.full_messages.to_sentence
    end
  end

  private

  def set_activity_event
    @activity_event = ActivityEvent.find(params[:activity_event_id])
  end

  def comment_params
    params.require(:activity_event_comment).permit(:body)
  end
end
