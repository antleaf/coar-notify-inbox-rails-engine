# frozen_string_literal: true

module CoarNotifyInbox
  class NotificationType < ApplicationRecord
    self.table_name = "coar_notify_inbox_notification_types"

    # SQLite stores JSON as TEXT
    attribute :notification_ids, :json, default: []

    validates :name, presence: true, uniqueness: true

    after_initialize :set_defaults

    # --------------------------------------------------
    # Concurrency-safe append of notification IDs
    # Uses optimistic locking (lock_version)
    # --------------------------------------------------
    def append_notification_id!(notification_id, max_retries: 5)
      retries ||= 0

      ids = (notification_ids || []).dup
      return if ids.include?(notification_id)

      ids << notification_id
      self.notification_ids = ids

      save!
    rescue ActiveRecord::StaleObjectError
      retries += 1
      raise if retries >= max_retries
      reload
      retry
    end

    private

    def set_defaults
      self.notification_ids ||= []
    end
  end
end
