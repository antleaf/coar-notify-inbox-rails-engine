module CoarNotifyInbox
  class Consumer < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'

    # Updated association to use the new join table
    has_many :consumer_targets, class_name: 'CoarNotifyInbox::ConsumerTarget', dependent: :destroy
    has_many :targets, through: :consumer_targets, class_name: 'CoarNotifyInbox::Target'
  end
end
