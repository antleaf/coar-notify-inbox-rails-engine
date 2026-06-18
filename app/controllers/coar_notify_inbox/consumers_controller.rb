# frozen_string_literal: true

module CoarNotifyInbox
  class ConsumersController < ApplicationController
    load_and_authorize_resource class: "CoarNotifyInbox::Consumer", except: [:create]

    # GET /consumers
    def index
      consumers = current_user.admin? ? Consumer.all.order(:id) : Consumer.for_user(current_user).order(:id)
      render json: consumers.as_json(only: %i[id username target_uri origin_uris active created_at updated_at])
    end

    # GET /consumers/:id
    def show
      render json: @consumer.as_json(only: %i[id username target_uri origin_uris active created_at updated_at])
    end

    # POST /consumers
    def create
      owner_username = current_user.username

      if current_user.admin? && params[:username].present?
        owner_username = params[:username].to_s
        unless CoarNotifyInbox::User.find_by(username: owner_username)&.active?
          return render json: { error: "Provided username not found or not active" }, status: :unprocessable_entity
        end
      end

      target_uri = params.dig(:consumer, :target_uri).to_s.strip
      unless target_uri.present?
        return render json: { error: "target_uri is required" }, status: :unprocessable_entity
      end

      if Consumer.exists?(username: owner_username, target_uri: target_uri)
        return render json: { error: "Consumer already exists; please update instead" }, status: :conflict
      end

      origin_uris = Array(params.dig(:consumer, :origin_uris)).map(&:to_s).reject(&:blank?)

      consumer = Consumer.new(
        username: owner_username,
        target_uri: target_uri,
        origin_uris: origin_uris
      )

      if current_user.admin?
        consumer.active = ActiveRecord::Type::Boolean.new.cast(params.dig(:consumer, :active))
      else
        consumer.active = false
      end

      if consumer.save
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: consumer.origin_uris,
            related_type: "consumer",
            related_id: consumer.id
          )

          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "target",
            uris: [consumer.target_uri].compact,
            related_type: "consumer",
            related_id: consumer.id
          )
        rescue => e
          Rails.logger.error("[ConsumersController] failed to enqueue origin/target jobs for consumer=#{consumer.id}: #{e.class} #{e.message}")
        end

        render json: consumer.as_json(only: %i[id username target_uri origin_uris active]), status: :created
      else
        render json: { error: consumer.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # PUT /consumers/:id
    def update
      consumer_params = params.require(:consumer).permit(:target_uri, :active, origin_uris: [])

      if consumer_params.key?(:target_uri) && consumer_params[:target_uri].present?
        new_target = consumer_params[:target_uri].to_s
        if Consumer.where(username: @consumer.username, target_uri: new_target).where.not(id: @consumer.id).exists?
          return render json: { error: "Consumer with this target already exists for this username" }, status: :conflict
        end
        @consumer.target_uri = new_target
      end

      if consumer_params.key?(:origin_uris)
        @consumer.origin_uris = Array(consumer_params[:origin_uris]).map(&:to_s).reject(&:blank?)
      end

      if consumer_params.key?(:active)
        desired_active = ActiveRecord::Type::Boolean.new.cast(consumer_params[:active])
        if desired_active && !current_user.admin?
          @consumer.active = false
        else
          @consumer.active = desired_active
        end
      end

      if @consumer.save
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: @consumer.origin_uris,
            related_type: "consumer",
            related_id: @consumer.id
          )

          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "target",
            uris: [@consumer.target_uri].compact,
            related_type: "consumer",
            related_id: @consumer.id
          )
        rescue => e
          Rails.logger.error("[ConsumersController] failed to enqueue origin/target jobs for consumer=#{@consumer.id}: #{e.class} #{e.message}")
        end

        render json: @consumer.as_json(only: %i[id username target_uri origin_uris active])
      else
        render json: { error: @consumer.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # PUT /consumers/:id/activate
    def activate
      unless current_user.admin?
        return render json: { error: "Only admin can activate consumers" }, status: :forbidden
      end

      @consumer.active = true
      if @consumer.save
        render json: @consumer.as_json(only: %i[id username target_uri origin_uris active])
      else
        render json: { error: @consumer.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end
  end
end
