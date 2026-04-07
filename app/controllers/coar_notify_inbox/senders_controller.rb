# frozen_string_literal: true

module CoarNotifyInbox
  class SendersController < ApplicationController
    # Use CanCan for load & authorization on most actions; create is custom
    load_and_authorize_resource class: "CoarNotifyInbox::Sender", except: [:create]

    # GET /senders
    def index
      senders = current_user.admin? ? Sender.all.order(:id) : Sender.for_user(current_user).order(:id)
      render json: senders.as_json(only: %i[id username origin_uri target_uris active created_at updated_at])
    end

    # GET /senders/:id
    def show
      render json: @sender.as_json(only: %i[id username origin_uri target_uris active created_at updated_at])
    end

    # POST /senders
    def create
      # Determine owner username:
      # - if current_user is admin and provides username -> use that (but validate existence & active)
      # - else use current_user.username
      owner_username = if current_user.admin? && create_params[:username].present?
                         create_params[:username].to_s
                       else
                         current_user.username
                       end

      # If admin provided username, ensure that user exists and is active
      if current_user.admin? && create_params[:username].present?
        owner_user = CoarNotifyInbox::User.find_by(username: owner_username)
        unless owner_user&.active?
          return render json: { error: "Provided username not found or not active" }, status: :unprocessable_entity
        end
      end

      origin_uri = create_params_origin_or_payload
      unless origin_uri.present?
        return render json: { error: "origin_uri is required" }, status: :unprocessable_entity
      end

      # Duplicate check: username + origin_uri
      if Sender.exists?(username: owner_username, origin_uri: origin_uri)
        return render json: { error: "Sender already exists; please update instead" }, status: :conflict
      end

      sender = Sender.new(
        username: owner_username,
        origin_uri: origin_uri,
        target_uris: create_params_target_uris
      )

      # active rules
      if current_user.admin?
        sender.active = ActiveRecord::Type::Boolean.new.cast(create_params.dig(:sender, :active))
      else
        sender.active = false
      end

      if sender.save
        # Enqueue background updates (non-blocking). Do this before rendering to be defensive.
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: [sender.origin_uri].compact,
            related_type: "sender",
            related_id: sender.id
          )

          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "target",
            uris: sender.target_uris || [],
            related_type: "sender",
            related_id: sender.id
          )
        rescue => e
          Rails.logger.error("[SendersController] failed to enqueue origin/target jobs for sender=#{sender.id}: #{e.class} #{e.message}")
          # do not raise — still return success to the client
        end

        render json: sender.as_json(only: %i[id username origin_uri target_uris active]), status: :created
      else
        render json: { error: sender.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # PUT /senders/:id
    # Only allow updating origin_uri and target_uris (and active but with restrictions)
    def update
      # origin change
      if update_params.key?(:origin_uri) && update_params[:origin_uri].present?
        new_origin = update_params[:origin_uri].to_s
        # uniqueness check: username + new_origin must not exist on other record
        if Sender.where(username: @sender.username, origin_uri: new_origin).where.not(id: @sender.id).exists?
          return render json: { error: "Sender with this origin already exists for this username" }, status: :conflict
        end

        @sender.origin_uri = new_origin
      end

      # target_uris replace (exact)
      if update_params.key?(:target_uris)
        # TODO: Clarify behavior — should target_uris be appended or fully replaced?
        # Current behavior: fully replace target_uris with exact payload.
        @sender.target_uris = update_params[:target_uris] || []
      end

      # Handle active: non-admins cannot set it true
      if update_params.key?(:active)
        desired_active = ActiveRecord::Type::Boolean.new.cast(update_params[:active])
        if desired_active && !current_user.admin?
          # Non-admin attempted to set true -> force false (ignore)
          @sender.active = false
        else
          @sender.active = desired_active
        end
      end

      if @sender.save

        # Enqueue background jobs to update origin/target indexes
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: [@sender.origin_uri].compact,
            related_type: "sender",
            related_id: @sender.id
          )

          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "target",
            uris: @sender.target_uris || [],
            related_type: "sender",
            related_id: @sender.id
          )
        rescue => e
          Rails.logger.error("[SendersController] failed to enqueue origin/target jobs for sender=#{@sender.id}: #{e.class} #{e.message}")
        end

        render json: @sender.as_json(only: %i[id username origin_uri target_uris active])
      else
        render json: { error: @sender.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # PUT /senders/:id/activate
    # Admin-only endpoint that activates the sender (sets active = true)
    def activate
      unless current_user.admin?
        return render json: { error: "Only admin can activate senders" }, status: :forbidden
      end

      @sender.active = true
      if @sender.save
        render json: @sender.as_json(only: %i[id username origin_uri target_uris active])
      else
        render json: { error: @sender.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    private

    # Strong params helpers
    def create_params
      # permit top-level username (admin only) and nested sender keys or top-level fields
      params.permit(:username, sender: %i[origin_uri active], target_uris: [])
    end

    def update_params
      # allow origin_uri, target_uris, active at top-level inside sender or at root
      if params[:sender].present?
        params.require(:sender).permit(:origin_uri, :active, target_uris: [])
      else
        params.permit(:origin_uri, :active, target_uris: [])
      end
    end

    def create_params_origin_or_payload
      # Accept origin_uri either under sender.origin_uri or top-level origin_uri
      if create_params[:sender].present? && create_params[:sender][:origin_uri].present?
        create_params[:sender][:origin_uri]
      else
        params[:origin_uri] || params.dig(:sender, :origin_uri)
      end
    end

    def create_params_target_uris
      # Accept target_uris either top-level or under sender
      if create_params[:sender].present? && create_params[:sender][:target_uris].present?
        create_params[:sender][:target_uris]
      else
        create_params[:target_uris] || params[:target_uris] || params.dig(:sender, :target_uris) || []
      end
    end
  end
end
