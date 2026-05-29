module Admin
  class SyncsController < ApplicationController
    before_action :require_authentication
    before_action :require_admin

    def create
      synced_count = Football::MatchSynchronizer.new.call
      redirect_to matches_path, notice: "#{synced_count} jogo(s) sincronizado(s)."
    rescue Football::ApiClient::ApiError => error
      redirect_to matches_path, alert: "Falha ao sincronizar jogos: #{error.message}"
    end
  end
end
