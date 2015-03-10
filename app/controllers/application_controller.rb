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

  def current_user_only!(user_id_param)
    if !current_user.admin? && user_id_param && current_user.id != user_id_param.to_i
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
