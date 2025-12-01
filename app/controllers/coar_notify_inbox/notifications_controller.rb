module CoarNotifyInbox
  class NotificationsController < ApplicationController
    before_action :set_notification, only: [:show, :destroy]

    # POST /notifications
    # Create a notification
    # Validates: auth_token (user), origin_uri (must exist in user's sender)
    def create
      # Validate origin_uri exists in user's sender
      origin = CoarNotifyInbox::Origin.find_by(uri: params[:origin_uri])
      return render json: { error: "Origin not found" }, status: :unprocessable_entity unless origin

      sender = CoarNotifyInbox::Sender.find_by(user_id: current_user.id, origin_id: origin.id)
      return render json: { error: "User is not a sender for this origin" }, status: :unprocessable_entity unless sender

      # Get or create target
      target = CoarNotifyInbox::Target.find_or_create_by(uri: params[:target_uri])

      # Get notification type
      notification_type = CoarNotifyInbox::NotificationType.find_by(notification_type: params[:type])
      return render json: { error: "Notification type not found" }, status: :unprocessable_entity unless notification_type

      # Check if notification already exists (for idempotency)
      existing = CoarNotifyInbox::Notification.find_by(
        user_id: current_user.id,
        notification_type_id: notification_type.id,
        origin_id: origin.id,
        target_id: target.id
      )

      if existing
        return render json: existing, status: :see_other
      end

      # Create notification
      @notification = CoarNotifyInbox::Notification.new(
        user_id: current_user.id,
        notification_type_id: notification_type.id,
        origin_id: origin.id,
        target_id: target.id,
        payload: params[:payload] || {}
      )

      if @notification.save
        render json: @notification, status: :created
      else
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /notifications
    # List all notifications
    # If admin: all notifications
    # If user: only user's notifications
    def index
      if current_user.admin?
        @notifications = CoarNotifyInbox::Notification.all
      else
        @notifications = CoarNotifyInbox::Notification.where(user_id: current_user.id)
      end

      render json: @notifications
    end

    # GET /notifications/search
    # List notifications by type and/or uri
    # Query params: type (sender or consumer), uri (origin_uri or target_uri)
    def search
      @notifications = CoarNotifyInbox::Notification.all

      # Apply role-based filter
      @notifications = @notifications.where(user_id: current_user.id) unless current_user.admin?

      # Filter by type and/or uri
      type = params[:type]
      uri = params[:uri]

      if type.present? && uri.present?
        if type == "sender"
          origin = CoarNotifyInbox::Origin.find_by(uri: uri)
          @notifications = @notifications.where(origin_id: origin.id) if origin
        elsif type == "consumer"
          target = CoarNotifyInbox::Target.find_by(uri: uri)
          @notifications = @notifications.where(target_id: target.id) if target
        end
      elsif uri.present?
        # Search by uri in both origin and target
        origin = CoarNotifyInbox::Origin.find_by(uri: uri)
        target = CoarNotifyInbox::Target.find_by(uri: uri)

        origin_ids = origin ? [origin.id] : []
        target_ids = target ? [target.id] : []

        @notifications = @notifications.where(origin_id: origin_ids).or(
          @notifications.where(target_id: target_ids)
        ) if origin_ids.present? || target_ids.present?
      elsif type.present?
        # If only type is provided, return empty (no uri to filter by)
        @notifications = @notifications.none
      end

      render json: @notifications
    end

    private

    def set_notification
      @notification = CoarNotifyInbox::Notification.find(params[:id])
    end
  end
end
