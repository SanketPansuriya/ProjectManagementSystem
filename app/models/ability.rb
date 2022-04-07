# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
   
    arr = Task.select(:sprint_id).where(user_id: user.id).map {|x| x.sprint_id}.uniq
    project_ids = Project.joins(:sprints).where(sprints: {id: arr}).ids
     
    can [:update, :edit], User, id: user.id
    can [:create,:show],Issue

    can [:edit,:update,:destroy], Issue,creator_id: user.id
    if user.has_role? "admin"
      can [:create_user,:destroy, :new,:edit], User #Admin Can not update profile for other user  
      can :manage, Role
      can :manage, Project
      can :manage, Task
      can :manage, Sprint
      can :change_user_role, User
      can :manage, Issue
    elsif user.has_role? "manager"
      # can :create, Project
      can %i[edit update destroy show project_status ], Project, creator_id: user.id
      can %i[new create] , Project
      can :manage, Task, sprint: {project: {creator_id: user.id}}
  
      can :manage, Sprint, project: { creator_id: user.id}

      can :project_status, Project, creator_id: user.id
      can :assign_issue, Project, creator_id: user.id # manager assign issue to other employee 
      can [:edit,:destroy], Issue, project: {creator_id: user.id}  # manager can edit issue if Manager is creator of project
      

    elsif user.has_role? "employee"
      can [:show, :edit], Task, user_id: user.id
      can [:show,:edit], Project do |project|
        project_ids.include? project.id
      end
      can :update_task_status, Task, user_id: user.id
      can [:assign_issue,:assign_issue_show], Issue,employee_id: user.id # employee can update thre own issue status 
      
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
