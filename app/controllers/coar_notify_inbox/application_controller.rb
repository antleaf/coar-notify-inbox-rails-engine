module CoarNotifyInbox
  class ApplicationController < ActionController::API
    attr_reader :current_user
    before_action :load_and_authenticate_current_user!
    rescue_from CanCan::AccessDenied do |_exception|
      render json: { error: "Access denied" }, status: :forbidden
    end

    private

    def load_and_authenticate_current_user!
      token = request.headers["Authorization"]&.split(" ")&.last
      @current_user = CoarNotifyInbox::User.find_by(auth_token: token, active: true)
      render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
    end
  end
end
