module CoarNotifyInbox
  class Consumer < ApplicationRecord
    belongs_to :user, class_name: 'CoarNotifyInbox::User'

    has_many :consumer_origins, class_name: 'CoarNotifyInbox::ConsumerOrigin', dependent: :destroy
    has_many :origins, through: :consumer_origins, class_name: 'CoarNotifyInbox::Origin'

    belongs_to :target, through: :consumer_target, class_name: 'CoarNotifyInbox::Target'
  end
end
