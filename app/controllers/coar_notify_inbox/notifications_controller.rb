# frozen_string_literal: true

module CoarNotifyInbox
  class NotificationsController < ApplicationController
    load_and_authorize_resource class: "CoarNotifyInbox::Notification"

    # ------------------------------------------------------------
    # POST /notifications
    # ------------------------------------------------------------
    def create
      begin
        Rails.logger.info("[NotificationsController] Received COAR Notify payload: #{request.raw_post}")
        raw_payload = JSON.parse(request.raw_post)
      rescue JSON::ParserError
        Rails.logger.error("[NotificationsController] Invalid JSON payload")
        return render json: { error: "Invalid JSON payload" }, status: :unprocessable_entity
      end

      # Resolve origin and target URIs — accept id or inbox, prefer id
      origin_uri = resolve_uri(raw_payload, "origin")
      target_uri = resolve_uri(raw_payload, "target")

      Rails.logger.info("[NotificationsController] Resolved origin_uri: #{origin_uri}, target_uri: #{target_uri}")
      Rails.logger.info("[NotificationsController] Notification type: #{raw_payload['type']}")
      unless raw_payload["type"].present? && origin_uri.present? && target_uri.present?

        Rails.logger.error("[NotificationsController] Missing required fields in COAR Notify payload (type, origin/target with id or inbox)")
        return render json: {
          error: "Invalid COAR Notify payload",
          details: "Missing required fields: type, and origin/target with id or inbox"
        }, status: :unprocessable_entity
      end

      begin
        Coarnotify::Validate.absolute_uri(nil, origin_uri)
        Coarnotify::Validate.absolute_uri(nil, target_uri)
      rescue ArgumentError => e
        Rails.logger.error("[NotificationsController] Invalid URI in COAR Notify payload: #{e.message}")
        return render json: { error: "Invalid COAR Notify payload", details: e.message }, status: :unprocessable_entity
      end

      username = current_user.username
      Rails.logger.info("[NotificationsController] Processing notification for user: #{username}")
      sender = CoarNotifyInbox::Sender.find_by(username: username, origin_uri: origin_uri)
      unless sender
        Rails.logger.error("[NotificationsController] Access denied: origin URI not registered for this user")
        return render json: { error: "Access denied: origin URI not registered for this user" }, status: :forbidden
      end

      type_name = Array(raw_payload["type"]).join(", ")
      notification_type = CoarNotifyInbox::NotificationType.find_or_create_by!(name: type_name)

      Rails.logger.info("[NotificationsController] Creating notification for user: #{username}, origin_uri: #{origin_uri}, target_uri: #{target_uri}, type: #{type_name}")
      notification = CoarNotifyInbox::Notification.new(
        username: username,
        origin_uri: origin_uri,
        target_uri: target_uri,
        raw_payload: raw_payload,
        notification_type: notification_type
      )

      if notification.save
        notification_type.append_notification_id!(notification.id)

        Rails.logger.info("[NotificationsController] Notification created successfully: #{notification.id}")
        # Auto-populate sender target_uris and consumer origin_uris from this notification
        populate_sender_target_uris(sender, target_uri)
        populate_consumer_origin_uris(origin_uri, target_uri)

        render json: {
          id: notification.id,
          username: notification.username,
          origin_uri: notification.origin_uri,
          target_uri: notification.target_uri,
          notification_type: notification_type.name,
          created_at: notification.created_at
        }, status: :created
      else
        Rails.logger.error("[NotificationsController] Failed to create notification: #{notification.errors.full_messages.join(', ')}")
        render json: { errors: notification.errors.full_messages }, status: :unprocessable_entity
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
      decoded_uri = CGI.unescape(raw_uri)
      normalized_uri =
        decoded_uri.sub(/\Ahttps:\//, "https://")
                  .sub(/\Ahttp:\//, "http://")
                  .strip

      notifications =
        case type
        when "sender"
          CoarNotifyInbox::Notification.by_origin(normalized_uri)
        when "consumer"
          CoarNotifyInbox::Notification.by_target(normalized_uri)
        else
          return render json: { error: "Invalid type. Must be 'sender' or 'consumer'." }, status: :unprocessable_entity
        end

      notifications = notifications.where(username: current_user.username) unless current_user.admin?

      render json: notifications.order(created_at: :desc), status: :ok
    end

    private

    def resolve_uri(payload, key)
      uri = payload.dig(key, "id").to_s.strip
      uri = payload.dig(key, "inbox").to_s.strip if uri.blank?
      uri.presence
    end

    def populate_sender_target_uris(sender, target_uri)
      return if sender.target_uris.include?(target_uri)
      sender.update(target_uris: sender.target_uris | [target_uri])
    rescue => e
      Rails.logger.error("[NotificationsController] failed to update sender target_uris: #{e.class} #{e.message}")
    end

    def populate_consumer_origin_uris(origin_uri, target_uri)
      CoarNotifyInbox::Consumer.where(target_uri: target_uri).find_each do |consumer|
        next if consumer.origin_uris.include?(origin_uri)
        consumer.update(origin_uris: consumer.origin_uris | [origin_uri])
      end
    rescue => e
      Rails.logger.error("[NotificationsController] failed to update consumer origin_uris: #{e.class} #{e.message}")
    end
  end
end
