class RankingsController < ApplicationController
  before_action :require_authentication

  def show
    @users = User.ranking
  end
end
