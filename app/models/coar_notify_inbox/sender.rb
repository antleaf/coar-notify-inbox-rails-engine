module CoarNotifyInbox
  class Sender < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'
    belongs_to :origin, class_name: 'CoarNotifyInbox::Origin', optional: true

    has_many :sender_targets, class_name: 'CoarNotifyInbox::SenderTarget', dependent: :destroy
    has_many :targets, through: :sender_targets, class_name: 'CoarNotifyInbox::Target'
  end
end
