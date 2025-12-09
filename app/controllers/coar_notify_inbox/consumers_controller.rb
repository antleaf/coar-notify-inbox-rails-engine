# frozen_string_literal: true

module CoarNotifyInbox
  class ConsumersController < ApplicationController
    # Use CanCan for loading and authorizing; create is custom (we resolve owner username)
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
      owner_username = if current_user.admin? && create_params[:username].present?
                         create_params[:username].to_s
                       else
                         current_user.username
                       end

      # If admin provided a username, validate existence and active
      if current_user.admin? && create_params[:username].present?
        owner_user = CoarNotifyInbox::User.find_by(username: owner_username)
        unless owner_user&.active?
          return render json: { error: "Provided username not found or not active" }, status: :unprocessable_entity
        end
      end

      target_uri = create_params_target_or_payload
      unless target_uri.present?
        return render json: { error: "target_uri is required" }, status: :unprocessable_entity
      end

      # Duplicate check: username + target_uri
      if Consumer.exists?(username: owner_username, target_uri: target_uri)
        return render json: { error: "Consumer already exists; please update instead" }, status: :conflict
      end

      consumer = Consumer.new(
        username: owner_username,
        target_uri: target_uri,
        origin_uris: create_params_origin_uris
      )

      # active rules
      if current_user.admin?
        consumer.active = ActiveRecord::Type::Boolean.new.cast(create_params.dig(:consumer, :active))
      else
        consumer.active = false
      end

      if consumer.save
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: consumer.origin_uris || [],
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
    # Only allow updating target_uri and origin_uris (and active with restrictions)
    def update
      # target_uri change
      if update_params.key?(:target_uri) && update_params[:target_uri].present?
        new_target = update_params[:target_uri].to_s

        if Consumer.where(username: @consumer.username, target_uri: new_target).where.not(id: @consumer.id).exists?
          return render json: { error: "Consumer with this target already exists for this username" }, status: :conflict
        end

        @consumer.target_uri = new_target
      end

      # origin_uris replace (exact)
      if update_params.key?(:origin_uris)
        # TODO: Clarify behavior — should origin_uris be appended or fully replaced?
        # Current behavior: fully replace origin_uris with exact payload.
        @consumer.origin_uris = update_params[:origin_uris] || []
      end

      # Handle active: non-admins cannot set it true
      if update_params.key?(:active)
        desired_active = ActiveRecord::Type::Boolean.new.cast(update_params[:active])
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
            uris: @consumer.origin_uris || [],
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
    # Admin-only endpoint that activates the consumer (sets active = true)
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

    private

    # Strong params helpers for create/update
    def create_params
      params.permit(:username, consumer: %i[target_uri active], origin_uris: [])
    end

    def update_params
      if params[:consumer].present?
        params.require(:consumer).permit(:target_uri, :active, origin_uris: [])
      else
        params.permit(:target_uri, :active, origin_uris: [])
      end
    end

    def create_params_target_or_payload
      # Accept target_uri either under consumer.target_uri or top-level target_uri
      if create_params[:consumer].present? && create_params[:consumer][:target_uri].present?
        create_params[:consumer][:target_uri]
      else
        params[:target_uri] || params.dig(:consumer, :target_uri)
      end
    end

    def create_params_origin_uris
      # Accept origin_uris either top-level or under consumer
      if create_params[:consumer].present? && create_params[:consumer][:origin_uris].present?
        create_params[:consumer][:origin_uris]
      else
        create_params[:origin_uris] || params[:origin_uris] || params.dig(:consumer, :origin_uris) || []
      end
    end
  end
end
