# frozen_string_literal: true

module CoarNotifyInbox
  class NotificationsController < ApplicationController
    # We cannot use automatic load_and_authorize_resource for create because we need to
    # parse & validate payload and to determine owner username from matched consumer.
    load_and_authorize_resource class: "CoarNotifyInbox::Notification", except: [:create, :by_type]

    # GET /notifications
    # Admin => list all, User => list only notifications where username == current_user.username
    def index
      scope = current_user.admin? ? Notification.all : Notification.where(username: current_user.username)
      notifs = scope.order(created_at: :desc)
      render json: notifs.as_json(only: %i[id username origin_uri target_uri payload created_at])
    end

    #
    # POST /notifications
    #
    # Flow & comments:
    # 1) Parse raw payload from request body (permit nested JSON)
    # 2) Validate using coarnotifyrb gem (Server.receive)
    # 3) Extract origin.inbox and target.inbox (matching rule)
    # 4) Find a Consumer with target_uri == target.inbox
    #    - If not found or consumer owner not active => reject (unprocessable_entity)
    #    - If found, owner_username = consumer.username
    # 5) Optionally extract/normalize notification type and find_or_create NotificationType
    # 6) Create Notification with username (consumer owner), origin_uri, target_uri and payload
    # 7) After save, append notification.id to notification_type.notification_ids (synchronous, retried)
    #
    def create
      # Step 1: read raw payload
      # Accept JSON body (use params/permitted or raw body)
      raw_payload =
        begin
          # If client sends JSON body, params may include structured hash.
          # We attempt to get raw permitted hash; fallback to request body parse.
          if request.body.present? && request.content_type&.include?("application/json")
            JSON.parse(request.body.read)
          else
            params.permit!.to_h
          end
        rescue JSON::ParserError => e
          return render json: { error: "Invalid JSON body: #{e.message}" }, status: :unprocessable_entity
        ensure
          # Rewind request body so further middleware won't break
          request.body.rewind if request.body.respond_to?(:rewind)
        end

      # Step 2: validate via coarnotifyrb gem
      begin
        # coarnotifyrb expects stringified keys in many cases; passing hash to Server.receive
        notif_obj = ::CoarNotifyRB::Server.receive(raw_payload.deep_stringify_keys)
      rescue => e
        return render json: { error: "Invalid COAR Notify payload: #{e.message}" }, status: :unprocessable_entity
      end

      # Step 3: extract inbox URIs
      origin_inbox = notif_obj&.origin&.inbox
      target_inbox = notif_obj&.target&.inbox

      unless origin_inbox.present? && target_inbox.present?
        return render json: { error: "origin.inbox and target.inbox are required" }, status: :unprocessable_entity
      end

      # Step 4: require matching consumer
      # Find consumer by target_uri
      consumer = CoarNotifyInbox::Consumer.find_by(target_uri: target_inbox)
      unless consumer&.owner&.active?
        return render json: { error: "No active consumer found for target.inbox" }, status: :unprocessable_entity
      end

      owner_username = consumer.username

      # Step 5: extract notification type (if present) and find_or_create
      notification_type = nil
      begin
        raw_type = nil
        if raw_payload.is_a?(Hash)
          t = raw_payload["type"] || raw_payload[:type]
          raw_type = t.is_a?(Array) ? t.first : t
        end

        if raw_type.present?
          normalized = CoarNotifyInbox::NotificationType.normalize_name(raw_type)
          notification_type = CoarNotifyInbox::NotificationType.find_or_create_by!(name: normalized) if normalized.present?
        end
      rescue => e
        Rails.logger.warn("[NotificationsController] failed to extract/create notification_type: #{e.class} #{e.message}")
        # continue; notification_type is optional
      end

      # Step 6: build and save notification
      notification = Notification.new(
        username: owner_username,
        origin_uri: origin_inbox,
        target_uri: target_inbox,
        payload: raw_payload
      )
      notification.notification_type = notification_type if notification_type.present?

      if notification.save
        # Step 7: append notification id to notification_type.notification_ids (synchronous)
        if notification_type.present?
          begin
            notification_type.append_notification_id!(notification.id)
          rescue => e
            # Log error — we do NOT fail the API because the notification itself is stored.
            Rails.logger.error("[NotificationsController] failed to append notification id to type=#{notification_type.id}: #{e.class} #{e.message}")
          end
        end

        render json: notification.as_json(
          only: %i[id username origin_uri target_uri payload created_at],
          include: { notification_type: { only: %i[id name label] } }
        ), status: :created
      else
        render json: { error: notification.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    #
    # GET /notifications/:type/:uri
    # type = "sender" => filter by origin_uri
    # type = "consumer" => filter by target_uri
    #
    def by_type
      type = params[:type]
      uri  = params[:uri]

      case type
      when "sender"
        scope = Notification.where(origin_uri: uri)
      when "consumer"
        scope = Notification.where(target_uri: uri)
      else
        return render json: { error: "Invalid type param" }, status: :bad_request
      end

      results = current_user.admin? ? scope : scope.where(username: current_user.username)

      render json: results.as_json(only: %i[id username origin_uri target_uri payload created_at])
    end
  end
end
