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
      # ----------------------------------------------------------
      # 1. Parse RAW JSON body (do NOT use params)
      # ----------------------------------------------------------
      begin
        raw_payload = JSON.parse(request.raw_post)
      rescue JSON::ParserError
        return render json: {
          error: "Invalid JSON payload"
        }, status: :unprocessable_entity
      end

      # ----------------------------------------------------------
      # 2. Basic required-field validation
      # ----------------------------------------------------------
      unless raw_payload["type"].present? &&
             raw_payload.dig("origin", "inbox").present? &&
             raw_payload.dig("target", "inbox").present?
        return render json: {
          error: "Invalid COAR Notify payload",
          details: "Missing required fields: type, origin.inbox, target.inbox"
        }, status: :unprocessable_entity
      end

      # ----------------------------------------------------------
      # 3. Normalize URIs
      # ----------------------------------------------------------
      origin_uri = raw_payload.dig("origin", "inbox").to_s.strip
      target_uri = raw_payload.dig("target", "inbox").to_s.strip

      # ----------------------------------------------------------
      # 4. Validate URIs using coarnotify helpers (CORRECT USAGE)
      # ----------------------------------------------------------
      begin
        Coarnotify::Validate.absolute_uri(nil, origin_uri)
        Coarnotify::Validate.absolute_uri(nil, target_uri)
      rescue ArgumentError => e
        return render json: {
          error: "Invalid COAR Notify payload",
          details: e.message
        }, status: :unprocessable_entity
      end

      # ----------------------------------------------------------
      # 5. Enforce sender ownership (hard check)
      # ----------------------------------------------------------
      username = current_user.username

      unless CoarNotifyInbox::Sender.exists?(username: username, origin_uri: origin_uri)
        return render json: {
          error: "Access denied: origin URI not registered for this user"
        }, status: :forbidden
      end

      # ----------------------------------------------------------
      # 6. Notification type (auto-managed)
      # ----------------------------------------------------------
      notification_type =
        CoarNotifyInbox::NotificationType.find_or_create_by!(
          name: raw_payload["type"]
        )

      # ----------------------------------------------------------
      # 7. Create notification (append-only)
      # ----------------------------------------------------------
      notification = CoarNotifyInbox::Notification.new(
        username: username,
        origin_uri: origin_uri,
        target_uri: target_uri,
        raw_payload: raw_payload,
        notification_type: notification_type
      )

      if notification.save
        # Keep reverse index updated
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

      raw_uri = params[:uri].to_s

      # Step 1: Decode if encoded
      decoded_uri = CGI.unescape(raw_uri)

      # Step 2: Normalize malformed scheme (Rails path parsing issue)
      normalized_uri =
        decoded_uri.sub(/\Ahttps:\//, "https://")
                  .sub(/\Ahttp:\//, "http://")
                  .strip

      Rails.logger.info("[Notifications#by_endpoint] type=#{type}")
      Rails.logger.info("[Notifications#by_endpoint] raw_uri='#{raw_uri}'")
      Rails.logger.info("[Notifications#by_endpoint] decoded_uri='#{decoded_uri}'")
      Rails.logger.info("[Notifications#by_endpoint] normalized_uri='#{normalized_uri}'")

      notifications =
        case type
        when "sender"
          CoarNotifyInbox::Notification.by_origin(normalized_uri)
        when "consumer"
          CoarNotifyInbox::Notification.by_target(normalized_uri)
        else
          return render json: {
            error: "Invalid type. Must be 'sender' or 'consumer'."
          }, status: :unprocessable_entity
        end

      notifications =
        notifications.where(username: current_user.username) unless current_user.admin?

      Rails.logger.info(
        "[Notifications#by_endpoint] result_count=#{notifications.count}"
      )

      render json: notifications.order(created_at: :desc), status: :ok
    end

  end
end
