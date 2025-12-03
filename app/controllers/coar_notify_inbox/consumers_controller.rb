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
      # Allow admin to create for another user
      user = if current_user&.admin? && consumer_params[:user_id].present?
               CoarNotifyInbox::User.find_by(id: consumer_params[:user_id])
             else
               current_user
             end

      return render json: { error: 'User not found or inactive' }, status: :unprocessable_entity unless user && user.active?

      # Determine target uri for uniqueness check
      target_uri = nil
      if params[:target_attributes].present?
        target_uri = params[:target_attributes].values.map { |t| t[:uri] }.first
      elsif params.dig(:consumer, :target_uri).present?
        target_uri = params.dig(:consumer, :target_uri)
      end

      if target_uri.present?
        target = CoarNotifyInbox::Target.find_or_create_by(uri: target_uri)
        if (existing = Consumer.find_by(user_id: user.id, target_id: target.id))
          # update origins on existing consumer
          process_origins(existing)
          if existing.save
            render json: existing, status: :ok, include: [:origins, :target]
          else
            render json: { errors: existing.errors.full_messages }, status: :unprocessable_entity
          end
          return
        end
      end

      @consumer = Consumer.new(consumer_params.except(:user_id))
      @consumer.user = user

      # Only admin may set active true
      if consumer_params.key?(:active) && consumer_params[:active].to_s == 'true' && !current_user&.admin?
        @consumer.active = false
      end

      process_origins(@consumer)
      process_target(@consumer)

      if @consumer.save
        render json: @consumer, status: :created, include: [:origins, :target]
      else
        render json: { errors: @consumer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PUT /consumers/:id
    def update
      # Allow admin to change owner
      if current_user&.admin? && consumer_params[:user_id].present?
        user = CoarNotifyInbox::User.find_by(id: consumer_params[:user_id])
        return render json: { error: 'User not found or inactive' }, status: :unprocessable_entity unless user && user.active?
        @consumer.user = user
      end

      @consumer.assign_attributes(consumer_params.except(:user_id))

      # Only admin may set active true
      if consumer_params.key?(:active) && consumer_params[:active].to_s == 'true' && !current_user&.admin?
        @consumer.active = false
      end

      process_origins(@consumer)
      process_target(@consumer)

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

    # Handle single target (consumer has one target)
    def process_target(consumer)
      uri = nil
      if params[:target_attributes].present?
        uri = params[:target_attributes].values.map { |t| t[:uri] }.first
      elsif params.dig(:consumer, :target_uri).present?
        uri = params.dig(:consumer, :target_uri)
      end

      return unless uri.present?

      target = CoarNotifyInbox::Target.find_or_create_by(uri: uri)

      # Replace existing consumer_target
      if consumer.respond_to?(:consumer_target) && consumer.consumer_target
        consumer.consumer_target.destroy
      end

      consumer.consumer_target = CoarNotifyInbox::ConsumerTarget.new(target: target)
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
