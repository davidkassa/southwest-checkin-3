class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  def authenticate_admin!
    authenticate_user!
    unless current_user.admin?
      redirect_to root_path, alert: 'You are not authorized.'
    end
  end
end
