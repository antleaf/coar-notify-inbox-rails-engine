class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest
    return unless user&.active?

    if user.admin?
      can :manage, :all
    else
      can :manage, CoarNotifyInbox::Sender, user_id: user.id
      can :manage, CoarNotifyInbox::Consumer, user_id: user.id
      can :deactivate, CoarNotifyInbox::User, id: user.id
    end
  end
end
