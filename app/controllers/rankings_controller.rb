class RankingsController < ApplicationController
  before_action :require_authentication

  def show
    @users = User.ranking.preload(user_achievements: :achievement)
    @top_adcoins_balance = User.maximum(:adcoins_balance).to_i
  end
end
