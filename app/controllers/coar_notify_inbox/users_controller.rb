module CoarNotifyInbox
  class UsersController < ApplicationController
    load_and_authorize_resource class: 'CoarNotifyInbox::User'

    # GET /users
    def index
      render json: @users.select(:id, :name, :role, :active, :created_at, :updated_at), status: :ok
    end

    # POST /users
    def create
      @user = CoarNotifyInbox::User.new(user_params.merge(active: true, role: :user))
      authorize! :create, @user

      if @user.save
        render json: { message: "User created", auth_token: @user.auth_token }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /users/:id/activate
    def activate
      @user.update(active: true)
      render json: { message: "User activated successfully" }, status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end

    # PATCH /users/:id/deactivate
    def deactivate
      @user.update(active: false)
      render json: { message: "User deactivated successfully" }, status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def user_params
      params.require(:user).permit(:name)
    end
  end
end
