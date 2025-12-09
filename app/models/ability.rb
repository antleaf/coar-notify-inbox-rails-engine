class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest
    return unless user&.active?

    if user.admin?
      can :manage, :all
    else
      can :manage, CoarNotifyInbox::Sender, username: user.username
      can :manage, CoarNotifyInbox::Consumer, username: user.username
      can :manage, CoarNotifyInbox::Notification, username: user.username
    end
  end
end
