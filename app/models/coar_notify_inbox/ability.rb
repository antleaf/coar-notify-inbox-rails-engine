# app/models/coar_notify_inbox/ability.rb
module CoarNotifyInbox
  class Ability
    include CanCan::Ability

    def initialize(user)
      return unless user&.active?

      if user.admin?
        can :manage, CoarNotifyInbox::User   # Admin can manage all users
      else
        cannot :manage, CoarNotifyInbox::User  # Normal users cannot manage
      end
    end
  end
end
