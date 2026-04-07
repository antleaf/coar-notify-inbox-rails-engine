# frozen_string_literal: true

module CoarNotifyInbox
  class Sender < ApplicationRecord
    self.table_name = "coar_notify_inbox_senders"

    # ----------------------
    # Validations
    # ----------------------
    validates :username, presence: true
    validates :origin_uri, presence: true
    validates :target_uris, presence: true
    validates :active, inclusion: { in: [true, false] }

    # uniqueness: username + origin_uri
    validates :origin_uri, uniqueness: { scope: :username, message: "already exists for this username" }

    # ----------------------
    # Serialization / storage
    # ----------------------
    # Use ActiveRecord attribute API for JSON casting and default value.
    # Works with SQLite (stored as TEXT) and Postgres (json/jsonb).
    attribute :target_uris, :json, default: []

    # ----------------------
    # Scopes / helpers
    # ----------------------
    scope :for_user, ->(user) { where(username: user.username) }

    # Returns the owner User record (may be nil)
    def owner
      CoarNotifyInbox::User.find_by(username: username)
    end

    # ----------------------
    # Immutability / Callbacks
    # ----------------------
    # Prevent accidental username changes (controller should never allow it either)
    before_update :prevent_username_change

    private

    def prevent_username_change
      if will_save_change_to_attribute?(:username)
        errors.add(:username, "cannot be changed")
        throw :abort
      end
    end
  end
end
