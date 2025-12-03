module CoarNotifyInbox
  class NotificationType < ApplicationRecord
    has_many :notifications, class_name: 'CoarNotifyInbox::Notification', dependent: :destroy

    validates :notification_type, presence: true
  end
end
