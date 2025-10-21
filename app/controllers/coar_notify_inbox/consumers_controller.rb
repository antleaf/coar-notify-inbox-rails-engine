module CoarNotifyInbox
  class ConsumersController < ApplicationController
    before_action :set_consumer, only: [:show, :update, :destroy]

    # GET /coar_notify_inbox/consumers
    def index
      consumers = Consumer.includes(:user, :targets).all
      render json: consumers.as_json(include: [:user, :targets])
    end

    # GET /coar_notify_inbox/consumers/:id
    def show
      render json: @consumer.as_json(include: [:user, :targets])
    end

    # POST /coar_notify_inbox/consumers
    def create
      consumer = Consumer.new(consumer_params)

      if consumer.save
        update_associations(consumer)
        render json: consumer.as_json(include: [:user, :targets]), status: :created
      else
        render json: { errors: consumer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /coar_notify_inbox/consumers/:id
    def update
      if @consumer.update(consumer_params)
        update_associations(@consumer)
        render json: @consumer.as_json(include: [:user, :targets])
      else
        render json: { errors: @consumer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /coar_notify_inbox/consumers/:id
    def destroy
      @consumer.destroy
      head :no_content
    end

    private

    def set_consumer
      @consumer = Consumer.find(params[:id])
    end

    # Handle association updates (OwnerTarget join table)
    def update_associations(consumer)
      return unless params[:targets].present?
      
      target_ids = params[:targets].map { |t| t[:id] }.compact
      
      # Replace existing associations cleanly
      consumer.owner_targets.destroy_all
      
      target_ids.each do |tid|
        consumer.owner_targets.create(target_id: tid)
      end
    end

    # Strong parameters (no target_ids here)
    def consumer_params
      params.require(:consumer).permit(:user_id)
    end
  end
end
