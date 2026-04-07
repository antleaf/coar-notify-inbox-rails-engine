# frozen_string_literal: true

module CoarNotifyInbox
  class Consumer < ApplicationRecord
    self.table_name = "coar_notify_inbox_consumers"

    # ----------------------
    # Validations
    # ----------------------
    validates :username, presence: true
    validates :target_uri, presence: true
    validates :origin_uris, presence: true
    validates :active, inclusion: { in: [true, false] }

    # uniqueness: username + target_uri
    validates :target_uri, uniqueness: { scope: :username, message: "already exists for this username" }

    # ----------------------
    # Serialization / storage
    # ----------------------
    # Use ActiveRecord attribute API for JSON casting and default value.
    attribute :origin_uris, :json, default: []

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
