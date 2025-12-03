module CoarNotifyInbox
  class UsersController < ApplicationController
    load_and_authorize_resource class: 'CoarNotifyInbox::User'

    # GET /users
    def index
      render json: @users.select(:id, :name, :role, :active, :created_at, :updated_at), status: :ok
    end

    # POST /users
    def create
      unless current_user&.admin?
        return render json: { error: 'Only admin can create users' }, status: :forbidden
      end

      attrs = user_params.to_h
      active_param = attrs.key?('active') ? attrs.delete('active') : nil

      @user = CoarNotifyInbox::User.new(attrs)
      @user.role = :user
      @user.active = active_param == true || active_param == 'true'

      authorize! :create, @user

      if @user.save
        render json: { message: "User created", auth_token: @user.auth_token }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /users/:id
    def show
      render json: @user.slice(:id, :name, :role, :active, :created_at, :updated_at), status: :ok
    end

    # PUT /users/:id
    def update
      attrs = params.require(:user).permit(:name, :username, :type, :active).to_h

      # Only admin may set active true
      if attrs.key?(:active)
        if current_user&.admin?
          # allow
        else
          attrs.delete(:active)
        end
      end

      if @user.update(attrs)
        render json: @user.slice(:id, :name, :role, :active, :created_at, :updated_at), status: :ok
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PUT /users/:id/auth_token
    def auth_token
      # Only admin can rotate another user's token
      unless current_user&.admin?
        return render json: { error: 'Only admin can regenerate auth_token' }, status: :forbidden
      end

      new_token = SecureRandom.hex(20)
      if @user.update(auth_token: new_token)
        render json: { auth_token: new_token }, status: :ok
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
      params.require(:user).permit(:name, :username)
    end
  end
end
