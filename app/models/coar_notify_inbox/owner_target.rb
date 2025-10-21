module CoarNotifyInbox
  class OwnerTarget < ApplicationRecord
    belongs_to :owner, polymorphic: true
    belongs_to :target, class_name: 'CoarNotifyInbox::Target'

    validates :owner_id, presence: true
    validates :target_id, presence: true
    validates :target_id, uniqueness: { scope: [:owner_type, :owner_id] }
  end
end
