# frozen_string_literal: true

module CoarNotifyInbox
  class NotificationType < ApplicationRecord
    self.table_name = "coar_notify_inbox_notification_types"

    attribute :notification_ids, :json, default: []

    validates :name, presence: true, uniqueness: true

    has_many :notifications,
             class_name: "CoarNotifyInbox::Notification",
             foreign_key: :notification_type_id,
             dependent: :nullify

    # Normalize raw payload type => canonical name
    def self.normalize_name(raw)
      return nil if raw.blank?

      # If array, pick first
      candidate = raw.is_a?(Array) ? raw.first : raw
      candidate = candidate.to_s
      # strip namespace if present (e.g., "coar-notify:ReviewAction")
      candidate = candidate.split(':').last if candidate.include?(':')
      candidate.strip
    end

    # Append a notification ID atomically (optimistic locking + retries)
    def append_notification_id!(notif_id, max_retries: 5)
      raise ArgumentError, "notif_id required" if notif_id.blank?

      attempts = 0
      begin
        attempts += 1
        # reload to get fresh lock_version
        reload
        current = Array(notification_ids || [])
        new_ids = (current | [notif_id]) # union to avoid duplicates
        update!(notification_ids: new_ids)
      rescue ActiveRecord::StaleObjectError => e
        raise if attempts >= max_retries
        sleep(0.01 * attempts)
        retry
      end
    end
  end
end
