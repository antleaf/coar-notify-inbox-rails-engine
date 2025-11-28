module CoarNotifyInbox
  class ConsumerOrigin < ApplicationRecord
    belongs_to :consumer, class_name: 'CoarNotifyInbox::Consumer'
    belongs_to :origin, class_name: 'CoarNotifyInbox::Origin'
  end
end
