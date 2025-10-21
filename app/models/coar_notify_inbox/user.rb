# app/models/coar_notify_inbox/user.rb
module CoarNotifyInbox
  class User < ApplicationRecord
    self.table_name = "users"  # points to users table

    before_create :generate_auth_token
    enum role: { user: 0, admin: 1 }

    validates :name, presence: true
    validates :auth_token, uniqueness: true

    before_validation :set_default_role, on: :create

    has_many :senders, class_name: 'CoarNotifyInbox::Sender', dependent: :destroy
    has_many :consumers, class_name: 'CoarNotifyInbox::Consumer', dependent: :destroy

    private

    def generate_auth_token
      self.auth_token ||= SecureRandom.hex(20)
    end

    def set_default_role
      self.role ||= :user
    end
  end
end
