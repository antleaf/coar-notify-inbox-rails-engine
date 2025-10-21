module CoarNotifyInbox
  class ApplicationController < ActionController::API
    rescue_from CanCan::AccessDenied do |_exception|
      render json: { error: "Access denied" }, status: :forbidden
    end

    private

    def authenticate_user!
      token = request.headers["Authorization"]&.split(" ")&.last
      @current_user = CoarNotifyInbox::User.find_by(auth_token: token, active: true)
      render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
    end

    def current_user
      @current_user
    end
  end
end
