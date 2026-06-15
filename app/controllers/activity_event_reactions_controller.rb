class ActivityEventReactionsController < ApplicationController
  before_action :require_authentication
  before_action :set_activity_event

  def create
    reaction = @activity_event.activity_event_reactions.find_or_initialize_by(
      user: current_user,
      reaction_type: reaction_type
    )

    if reaction.persisted? || reaction.save
      redirect_to mural_path(anchor: "mural"), notice: "Reacao registrada."
    else
      redirect_to mural_path(anchor: "mural"), alert: reaction.errors.full_messages.to_sentence
    end
  end

  def destroy
    @activity_event.activity_event_reactions
      .where(user: current_user, reaction_type: reaction_type)
      .destroy_all

    redirect_to mural_path(anchor: "mural"), notice: "Reacao removida."
  end

  private

  def set_activity_event
    @activity_event = ActivityEvent.find(params[:activity_event_id])
  end

  def reaction_type
    params[:reaction_type].to_s
  end
end
