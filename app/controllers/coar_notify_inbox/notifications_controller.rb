# frozen_string_literal: true

module CoarNotifyInbox
  class NotificationsController < ApplicationController
    load_and_authorize_resource class: "CoarNotifyInbox::Notification"

    # ------------------------------------------------------------
    # POST /notifications
    #
    # Append-only notification inbox.
    # ------------------------------------------------------------
    def create
      # 1. Read raw JSON payload exactly as sent
      raw_payload = params.to_unsafe_h

      # 2. Validate payload using coarnotifyrb (schema + structure)
      begin
        server = CoarNotify::Server.new
        server.receive(raw_payload)
      rescue StandardError => e
        return render json: {
          error: "Invalid COAR Notify payload",
          details: e.message
        }, status: :unprocessable_entity
      end

      # 3. Extract origin and target inbox URIs
      origin_uri = raw_payload.dig("origin", "inbox")
      target_uri = raw_payload.dig("target", "inbox")

      if origin_uri.blank? || target_uri.blank?
        return render json: {
          error: "Invalid notification payload: missing origin.inbox or target.inbox"
        }, status: :unprocessable_entity
      end

      # 4. Username context
      username = current_user.username

      # 5. HARD CHECK — sender ownership (ENABLED)
      sender_exists = CoarNotifyInbox::Sender.exists?(
        username: username,
        origin_uri: origin_uri
      )

      unless sender_exists
        return render json: {
          error: "Access denied: origin URI not registered for this user"
        }, status: :forbidden
      end

      # ----------------------------------------------------------
      # SOFT CHECK — consumer ownership (COMMENTED)
      #
      # consumer_exists = CoarNotifyInbox::Consumer.exists?(
      #   username: username,
      #   target_uri: target_uri
      # )
      #
      # unless consumer_exists
      #   return render json: {
      #     error: "Access denied: target URI not registered for this user"
      #   }, status: :forbidden
      # end
      # ----------------------------------------------------------

      # 6. Determine notification type
      notification_type_name = raw_payload["type"].presence || "unknown"

      notification_type =
        CoarNotifyInbox::NotificationType.find_or_create_by!(
          name: notification_type_name
        )

      # 7. Create notification (append-only)
      notification = CoarNotifyInbox::Notification.new(
        username: username,
        origin_uri: origin_uri,
        target_uri: target_uri,
        raw_payload: raw_payload,
        notification_type: notification_type
      )

      if notification.save
        # 8. Synchronously update notification type index
        notification_type.append_notification_id!(notification.id)

        render json: {
          id: notification.id,
          username: notification.username,
          origin_uri: notification.origin_uri,
          target_uri: notification.target_uri,
          notification_type: notification_type.name,
          created_at: notification.created_at
        }, status: :created
      else
        render json: {
          errors: notification.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # ------------------------------------------------------------
    # GET /notifications
    # ------------------------------------------------------------
    def index
      notifications =
        if current_user.admin?
          CoarNotifyInbox::Notification.all
        else
          CoarNotifyInbox::Notification.for_user(current_user)
        end

      render json: notifications.order(created_at: :desc), status: :ok
    end

    # ------------------------------------------------------------
    # GET /notifications/:type/:uri
    # ------------------------------------------------------------
    def by_endpoint
      type = params[:type]
      uri  = params[:uri]

      notifications =
        case type
        when "sender"
          CoarNotifyInbox::Notification.by_origin(uri)
        when "consumer"
          CoarNotifyInbox::Notification.by_target(uri)
        else
          return render json: {
            error: "Invalid type. Must be 'sender' or 'consumer'."
          }, status: :unprocessable_entity
        end

      notifications =
        notifications.where(username: current_user.username) unless current_user.admin?

      render json: notifications.order(created_at: :desc), status: :ok
    end
  end
end
