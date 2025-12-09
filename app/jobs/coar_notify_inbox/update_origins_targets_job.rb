# frozen_string_literal: true

module CoarNotifyInbox
  class UpdateOriginsTargetsJob < ApplicationJob
    queue_as :default

    # payload:
    # kind: "origin" or "target"
    # uris: array of uri strings
    # related_type: "sender" or "consumer"
    # related_id: integer resource id
    MAX_RETRIES = 5
    RETRY_DELAY_SECONDS = 0.1

    def perform(kind:, uris:, related_type:, related_id:)
      return if uris.blank?

      klass = kind == "origin" ? CoarNotifyInbox::Origin : CoarNotifyInbox::Target

      Array(uris).each do |uri|
        next if uri.blank?

        attempt = 0
        begin
          attempt += 1
          # Use find_or_initialize to avoid race on missing record
          record = klass.find_by(uri: uri)

          if record.nil?
            # try creating
            begin
              record = klass.create!(uri: uri,
                                     senders: (related_type == "sender" ? [related_id] : []),
                                     consumers: (related_type == "consumer" ? [related_id] : []))
            rescue ActiveRecord::RecordNotUnique, SQLite3::ConstraintException
              # Someone else created at the same time; find it and continue to update
              record = klass.find_by(uri: uri)
              raise unless record # if still nil, bubble up
            end
          else
            # add id to array in an optimistic-lock-safe way
            if related_type == "sender"
              new_ids = Array(record.senders) | [related_id]
              record.update!(senders: new_ids)
            else
              new_ids = Array(record.consumers) | [related_id]
              record.update!(consumers: new_ids)
            end
          end
        rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique, SQLite3::BusyException => e
          if attempt <= MAX_RETRIES
            sleep(RETRY_DELAY_SECONDS * attempt)
            retry
          else
            Rails.logger.warn("[UpdateOriginsTargetsJob] failed to update #{kind} #{uri} after #{attempt} attempts: #{e.class} #{e.message}")
          end
        rescue StandardError => e
          Rails.logger.error("[UpdateOriginsTargetsJob] unexpected error for #{kind} #{uri}: #{e.class} #{e.message}")
        end
      end
    end
  end
end
