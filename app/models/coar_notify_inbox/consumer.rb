module CoarNotifyInbox
  class Consumer < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'

    has_many :owner_targets, class_name: 'CoarNotifyInbox::OwnerTarget', as: :owner, dependent: :destroy
    has_many :targets, through: :owner_targets, class_name: 'CoarNotifyInbox::Target'
  end
end
