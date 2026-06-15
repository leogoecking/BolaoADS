class MuralsController < ApplicationController
  before_action :require_authentication

  def show
    @activity_events = ActivityEvent.recent.limit(20)
  end
end
