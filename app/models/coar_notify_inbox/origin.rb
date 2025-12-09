# frozen_string_literal: true

module CoarNotifyInbox
  class Origin < ApplicationRecord
    self.table_name = "coar_notify_inbox_origins"

    attribute :senders, :json, default: []
    attribute :consumers, :json, default: []

    validates :uri, presence: true, uniqueness: true

    # add sender id to senders array (idempotent)
    def add_sender_id!(id)
      ids = (senders || [])
      new_ids = (ids | [id])
      update!(senders: new_ids)
    end

    def add_consumer_id!(id)
      ids = (consumers || [])
      new_ids = (ids | [id])
      update!(consumers: new_ids)
    end
  end
end
