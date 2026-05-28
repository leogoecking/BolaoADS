module Admin
  class SyncsController < ApplicationController
    before_action :require_authentication
    before_action :require_admin

    def create
      MatchSyncJob.perform_later
      redirect_to matches_path, notice: "Sincronizacao agendada."
    end
  end
end
