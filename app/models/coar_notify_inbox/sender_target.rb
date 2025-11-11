module CoarNotifyInbox
  class SenderTarget < ApplicationRecord
    belongs_to :sender, class_name: 'CoarNotifyInbox::Sender'
    belongs_to :target, class_name: 'CoarNotifyInbox::Target'
  end
end
