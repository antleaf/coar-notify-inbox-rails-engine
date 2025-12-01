module CoarNotifyInbox
  class ConsumersController < ApplicationController
    before_action :set_consumer, only: [:show, :update, :destroy]
    load_and_authorize_resource

    # GET /consumers
    def index
      render json: @consumers, include: [:origins, :target]
    end

    # GET /consumers/:id
    def show
      render json: @consumer, include: [:origins, :target]
    end

    # POST /consumers
    def create
      @consumer = Consumer.new(consumer_params)
      @consumer.user = current_user

      process_origins(@consumer)

      if @consumer.save
        render json: @consumer, status: :created, include: [:origins, :target]
      else
        render json: { errors: @consumer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PUT /consumers/:id
    def update
      @consumer.assign_attributes(consumer_params)
      process_origins(@consumer)

      if @consumer.save
        render json: @consumer, include: [:origins, :target]
      else
        render json: { errors: @consumer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /consumers/:id
    def destroy
      @consumer.destroy
      head :no_content
    end

    private

    def set_consumer
      @consumer = Consumer.find(params[:id])
    end

    # Strong parameters
    def consumer_params
      params.require(:consumer).permit(:user_id, :active)
    end

    # Handle multiple origins
    def process_origins(consumer)
      return unless params[:origin_attributes].present?

      origin_uris = params[:origin_attributes].values.map { |o| o[:uri] }

      consumer.consumer_origins.destroy_all

      origin_uris.each do |uri|
        origin = CoarNotifyInbox::Origin.find_or_create_by(uri: uri)
        consumer.consumer_origins.create(origin: origin)
      end
    end
  end
end
