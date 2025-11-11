module CoarNotifyInbox
  class ConsumersController < ApplicationController
    before_action :set_consumer, only: [:show, :update, :destroy]

    # GET /coar_notify_inbox/consumers
    def index
      @consumers = Consumer.all
      render json: @consumers
    end

    # GET /coar_notify_inbox/consumers/:id
    def show
      render json: @consumer
    end

    # POST /coar_notify_inbox/consumers
    def create
      @consumer = Consumer.new(consumer_params)

      if @consumer.save
        render json: @consumer, status: :created
      else
        render json: { errors: @consumer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /coar_notify_inbox/consumers/:id
    def update
      if @consumer.update(consumer_params)
        render json: @consumer
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

    def consumer_params
      params.require(:consumer).permit(:user_id, :origin_id)
    end
  end
end
