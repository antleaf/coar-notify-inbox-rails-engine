module CoarNotifyInbox
  class Consumer < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'

    # Updated association to use the new join table
    has_many :consumer_origins, class_name: 'CoarNotifyInbox::ConsumerOrigin', dependent: :destroy
    has_many :origins, through: :consumer_origins, class_name: 'CoarNotifyInbox::Origin'
  end
end
