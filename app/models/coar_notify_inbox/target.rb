module CoarNotifyInbox
  class Target < ApplicationRecord
    validates :uri, presence: true, uniqueness: true
  end
end
