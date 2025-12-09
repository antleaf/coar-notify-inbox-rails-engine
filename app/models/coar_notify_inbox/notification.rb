# frozen_string_literal: true

module CoarNotifyInbox
  class Notification < ApplicationRecord
    self.table_name = "coar_notify_inbox_notifications"

    attribute :payload, :json, default: {}

    validates :username, presence: true
    validates :origin_uri, presence: true
    validates :target_uri, presence: true
    validates :payload, presence: true

    belongs_to :notification_type,
               class_name: "CoarNotifyInbox::NotificationType",
               optional: true,
               foreign_key: :notification_type_id

    # convenience: owner user (may be nil)
    def owner
      CoarNotifyInbox::User.find_by(username: username)
    end
  end
end
