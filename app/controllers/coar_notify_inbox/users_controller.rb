module CoarNotifyInbox
  class UsersController < ApplicationController
    load_and_authorize_resource class: 'CoarNotifyInbox::User'

    # GET /users
    def index
      render json: @users.select(:id, :name, :username, :role, :active, :created_at, :updated_at), status: :ok
    end

    # POST /users
    def create
      unless current_user&.admin?
        return render json: { error: 'Only admin can create users' }, status: :forbidden
      end

      attrs        = user_params.to_h
      role_param   = attrs.delete('role')
      active_param = attrs.delete('active')

      # Username existence pre-check
      if CoarNotifyInbox::User.exists?(username: attrs['username'])
        return render json: { error: 'User already exists' }, status: :conflict
      end

      @user = CoarNotifyInbox::User.new(attrs)

      # ROLE: allow admin to set :user or :admin, fallback to model default (:user)
      if role_param.present?
        unless %w[user admin].include?(role_param)
          return render json: { error: 'Invalid role' }, status: :unprocessable_entity
        end

        @user.role = role_param
      end
      # If role_param is nil, your before_validation :set_default_role kicks in and sets :user.

      
      @user.active = ActiveModel::Type::Boolean.new.cast(active_param || false)

      authorize! :create, @user

      if @user.save
        render json: { message: "User created", auth_token: @user.auth_token }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end



    # GET /users/:id
    def show
      render json: @user.slice(:id, :name, :username, :role, :active, :created_at, :updated_at), status: :ok
    end

    # PUT /users/:id
    def update
      attrs = params.require(:user).permit(:name, :type, :active).to_h

      # Only admin may set active true
      if attrs.key?(:active)
        if current_user&.admin?
          # allow
        else
          attrs.delete(:active)
        end
      end

      if @user.update(attrs)
        render json: @user.slice(:id, :name, :active, :created_at, :updated_at), status: :ok
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

    # PUT /users/:id/activate
    def activate

      unless current_user&.admin?
        return render json: { error: 'Only admin can activate user' }, status: :forbidden
      end

      @user.update(active: true)
      render json: { message: "User activated successfully" }, status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def user_params
      params.require(:user).permit(:name, :username, :role, :active)
    end
  end
end
