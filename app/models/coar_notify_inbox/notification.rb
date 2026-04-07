# frozen_string_literal: true

module CoarNotifyInbox
  class Notification < ApplicationRecord
    self.table_name = "coar_notify_inbox_notifications"

    belongs_to :notification_type,
               class_name: "CoarNotifyInbox::NotificationType"

    # Rails 8 JSON handling (SQLite compatible)
    attribute :raw_payload, :json, default: {}

    # ----------------------
    # Validations
    # ----------------------
    validates :username, presence: true
    validates :origin_uri, presence: true
    validates :target_uri, presence: true
    validates :raw_payload, presence: true
    validates :notification_type, presence: true

    # ----------------------
    # Scopes
    # ----------------------
    scope :for_user, ->(user) { where(username: user.username) }
    scope :by_origin, ->(uri) { where(origin_uri: uri) }
    scope :by_target, ->(uri) { where(target_uri: uri) }
  end
end
