# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    arr = Task.select(:sprint_id).where(user_id: user.id).map {|x| x.sprint_id}.uniq
    project_ids = Project.joins(:sprints).where(sprints: {id: arr}).ids
    can [:update, :edit], User, id: user.id

    if user.has_role? "admin"
      can [:create_user,:destroy], User #Admin Can not update profile for other user  
      can :manage, Role
      can :manage, Project
    elsif user.has_role? "manager"
      can :manage, Project, creator_id: user.id
      can :manage, Task
      
    elsif user.has_role? "employee"
      can [:show, :edit], Task, user_id: user.id
      can [:show,:edit], Project do |project|
        project_ids.include? project.id
      end
      can :update_task_status, Task, user_id: user.id
    else
      can :show, Project, client_id: user.id
      can :review_rating, Project
      can :show, Task 

    end

    # if user.manager?
    #   can :edit
    # end
  end
end
