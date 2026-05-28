class AchievementsController < ApplicationController
  before_action :require_authentication

  def show
    Achievement.ensure_catalog!
    @achievements = Achievement.order(:id)
    @unlocked_by_key = current_user.user_achievements.includes(:achievement).index_by { |user_achievement| user_achievement.achievement.key }
  end
end
