module CoarNotifyInbox
  class Sender < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'
    belongs_to :origin, class_name: 'CoarNotifyInbox::Origin', optional: true

    # Use polymorphic OwnerTarget join model
    has_many :owner_targets, class_name: 'CoarNotifyInbox::OwnerTarget', as: :owner, dependent: :destroy
    has_many :targets, through: :owner_targets, class_name: 'CoarNotifyInbox::Target'
  end
end
