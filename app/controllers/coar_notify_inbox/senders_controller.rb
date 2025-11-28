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
      @sender = Sender.new(sender_params)
      @sender.user = current_user

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
