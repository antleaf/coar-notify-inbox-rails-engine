module CoarNotifyInbox
  class SendersController < ApplicationController
    before_action :set_sender, only: [:show, :update, :destroy]
    load_and_authorize_resource

    # GET /senders
    def index
      # @senders is automatically scoped by CanCanCan
      render json: @senders, include: [:origin, :targets]
    end

    # GET /senders/:id
    def show
      render json: @sender, include: [:origin, :targets]
    end

    # POST /senders
    def create
      # Determine user: admin may create for another user via user_id param
      user = if current_user&.admin? && sender_params[:user_id].present?
               CoarNotifyInbox::User.find_by(id: sender_params[:user_id])
             else
               current_user
             end

      return render json: { error: 'User not found or inactive' }, status: :unprocessable_entity unless user && user.active?

      # Ensure origin exists and enforce uniqueness (user + origin)
      origin_uri = sender_params.dig(:origin_attributes, :uri)
      origin = CoarNotifyInbox::Origin.find_or_create_by(uri: origin_uri) if origin_uri.present?

      if origin && (existing = Sender.find_by(user_id: user.id, origin_id: origin.id))
        # Update targets on existing sender
        process_targets(existing)
        if existing.save
          render json: existing, status: :ok, include: [:origin, :targets]
        else
          render json: { errors: existing.errors.full_messages }, status: :unprocessable_entity
        end
        return
      end

      @sender = Sender.new(sender_params.except(:user_id))
      @sender.user = user

      # Only admin may set active true
      if sender_params.key?(:active) && sender_params[:active].to_s == 'true' && !current_user&.admin?
        @sender.active = false
      end

      process_targets(@sender)

      if @sender.save
        render json: @sender, status: :created, include: [:origin, :targets]
      else
        render json: { errors: @sender.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PUT /senders/:id
    def update
      @sender.assign_attributes(sender_params)
      process_targets(@sender)

      if @sender.save
        render json: @sender, include: [:origin, :targets]
      else
        render json: { errors: @sender.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /senders/:id
    def destroy
      @sender.destroy
      head :no_content
    end

    private

    # Find sender by ID
    def set_sender
      @sender = Sender.find(params[:id])
    end

    # Strong parameters
    def sender_params
      params.require(:sender).require(:origin_attributes) # origin is required
      params.require(:sender).permit(
        :user_id,
        :active,
        :origin_id,
        origin_attributes: [:uri] # only one origin allowed
      )
    end

    # Handle multiple targets
    def process_targets(sender)
      return unless params[:target_attributes].present?

      target_uris = params[:target_attributes].values.map { |t| t[:uri] }

      # Clear existing targets
      sender.sender_targets.destroy_all

      # Find or create targets and associate
      target_uris.each do |uri|
        target = CoarNotifyInbox::Target.find_or_create_by(uri: uri)
        sender.sender_targets.create(target: target)
      end
    end
  end
end
