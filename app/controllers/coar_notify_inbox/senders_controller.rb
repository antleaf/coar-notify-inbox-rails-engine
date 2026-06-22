# frozen_string_literal: true

module CoarNotifyInbox
  class SendersController < ApplicationController
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
      owner_username = current_user.username

      if current_user.admin? && params[:username].present?
        owner_username = params[:username].to_s
        unless CoarNotifyInbox::User.find_by(username: owner_username)&.active?
          return render json: { error: "Provided username not found or not active" }, status: :unprocessable_entity
        end
      end

      origin_uri = params.dig(:sender, :origin_uri).to_s.strip
      unless origin_uri.present?
        return render json: { error: "origin_uri is required" }, status: :unprocessable_entity
      end

      if Sender.exists?(username: owner_username, origin_uri: origin_uri)
        return render json: { error: "Sender already exists; please update instead" }, status: :conflict
      end

      target_uris = Array(params.dig(:sender, :target_uris)).map(&:to_s).reject(&:blank?)

      sender = Sender.new(
        username: owner_username,
        origin_uri: origin_uri,
        target_uris: target_uris
      )

      if current_user.admin?
        sender.active = ActiveRecord::Type::Boolean.new.cast(params.dig(:sender, :active))
      else
        sender.active = false
      end

      if sender.save
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: [sender.origin_uri].compact,
            related_type: "sender",
            related_id: sender.id
          )

          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "target",
            uris: sender.target_uris,
            related_type: "sender",
            related_id: sender.id
          )
        rescue => e
          Rails.logger.error("[SendersController] failed to enqueue origin/target jobs for sender=#{sender.id}: #{e.class} #{e.message}")
        end

        render json: sender.as_json(only: %i[id username origin_uri target_uris active]), status: :created
      else
        render json: { error: sender.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    # PUT /senders/:id
    def update
      sender_params = params.require(:sender).permit(:origin_uri, :active, target_uris: [])

      if sender_params.key?(:origin_uri) && sender_params[:origin_uri].present?
        new_origin = sender_params[:origin_uri].to_s
        if Sender.where(username: @sender.username, origin_uri: new_origin).where.not(id: @sender.id).exists?
          return render json: { error: "Sender with this origin already exists for this username" }, status: :conflict
        end
        @sender.origin_uri = new_origin
      end

      if sender_params.key?(:target_uris)
        @sender.target_uris = Array(sender_params[:target_uris]).map(&:to_s).reject(&:blank?)
      end

      if sender_params.key?(:active)
        desired_active = ActiveRecord::Type::Boolean.new.cast(sender_params[:active])
        if desired_active && !current_user.admin?
          @sender.active = false
        else
          @sender.active = desired_active
        end
      end

      if @sender.save
        begin
          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "origin",
            uris: [@sender.origin_uri].compact,
            related_type: "sender",
            related_id: @sender.id
          )

          CoarNotifyInbox::UpdateOriginsTargetsJob.perform_later(
            kind: "target",
            uris: @sender.target_uris,
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
  end
end
