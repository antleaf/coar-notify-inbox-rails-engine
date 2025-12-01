module CoarNotifyInbox
  class Notification < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'
    belongs_to :notification_type, class_name: 'CoarNotifyInbox::NotificationType'
    belongs_to :origin, class_name: 'CoarNotifyInbox::Origin'
    belongs_to :target, class_name: 'CoarNotifyInbox::Target'

    validates :user_id, :notification_type_id, :origin_id, :target_id, presence: true
    validate :validate_origin_and_target_for_sender

    private

    def validate_origin_and_target_for_sender
      # Ensure the user is a sender with this origin
      return unless user && origin

      sender = CoarNotifyInbox::Sender.find_by(user_id: user.id)
      return if sender&.origin_id == origin.id

      errors.add(:origin, "User does not have this origin in their sender configuration")
    end
  end
end
