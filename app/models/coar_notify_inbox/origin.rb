module CoarNotifyInbox
  class Origin < ApplicationRecord
    validates :uri, presence: true, uniqueness: true
  end
end
