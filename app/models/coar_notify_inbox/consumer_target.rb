module CoarNotifyInbox
  class ConsumerTarget < ApplicationRecord
    belongs_to :consumer, class_name: 'CoarNotifyInbox::Consumer'
    belongs_to :target, class_name: 'CoarNotifyInbox::Target'
  end
end
