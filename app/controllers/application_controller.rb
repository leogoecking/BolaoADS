class ApplicationController < ActionController::Base
  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    current_user.present?
  end

  def require_authentication
    return if signed_in?

    redirect_to new_session_path, alert: "Faca login para continuar."
  end

  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: "Acesso restrito."
  end
end
