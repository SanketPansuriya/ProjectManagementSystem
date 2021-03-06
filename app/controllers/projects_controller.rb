# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]
  before_action :set_project_by_format, only: %i[project_status]
  before_action :checking_authenticity_update, only: %i[edit update destroy]
  before_action :checking_authenticity_show, only: %i[show]
  before_action :checking_authenticity_status, only: %i[project_status]
  before_action :checking_authenticity_new, only: %i[new create]
  # GET /projects or /projects.json
  def index
    # if current_user.has_role? 'employee'
    #   arr = Task.select(:sprint_id).where(user_id: current_user.id).map(&:sprint_id).uniq
    #   @projects = Project.joins(:sprints).where(sprints: { id: arr })
    #   return @projects
    # end
    # @projects = Project.all


    @filterrific = initialize_filterrific(
      Project,
      params[:filterrific],
      select_options: {
        sorted_by: Project.options_for_sorted_by,
        with_status: Project.options_for_with_status,
      },
      persistence_id: "shared_key",
      default_filter_params: {},
      available_filters: [:sorted_by, :with_status, :search_query],
      sanitize_params: true,
    ) || return
    # Get an ActiveRecord::Relation for all students that match the filter settings.
    # You can paginate with will_paginate or kaminari.
    # NOTE: filterrific_find returns an ActiveRecord Relation that can be
    # chained with other scopes to further narrow down the scope of the list,
    # e.g., to apply permissions or to hard coded exclude certain types of records.
    if current_user.has_role? 'employee'
      arr = Task.select(:sprint_id).where(user_id: current_user.id).map(&:sprint_id).uniq
      @projects = @filterrific.find.page(params[:page]).joins(:sprints).where(sprints: { id: arr }).paginate(page: params[:page], per_page: 9)
      # return @projects
    else 
      @projects = @filterrific.find.page(params[:page]).paginate(page: params[:page], per_page: 9)
    end
    # @projects = Project.all

    # Respond to html for initial page load and to js for AJAX filter updates.
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    # project_id = params[:id]
    # @sprint = Sprint.where(project_id: project_id).all
    # @completed = Project.find(project_id).sprints.joins(:tasks).where(tasks: { status: 'Done' }).count
    # @ongoing = Project.find(project_id).sprints.joins(:tasks).count - @completed

    @filterrific = initialize_filterrific(
      Sprint,
      params[:filterrific],
      select_options: {
        sprint_sorted_by: Sprint.options_for_sorted_by,
        with_sprint_status: Sprint.options_for_with_status,
      },
      persistence_id: "shared_key",
      default_filter_params: {},
      available_filters: [:sprint_sorted_by, :sprint_search_query, :with_sprint_status],
      sanitize_params: true,
    ) || return

    project_id = params[:id]
    @sprint = @filterrific.find.page(params[:page]).where(project_id: project_id).paginate(page: params[:page], per_page: 9)
    @completed = Project.find(project_id).sprints.joins(:tasks).where(tasks: { status: 'Done' }).count
    @ongoing = Project.find(project_id).sprints.joins(:tasks).count - @completed
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @client = []
    @manager = []
    User.joins(:roles).where(roles: { name: 'customer' }).select(:id, :name).each { |v| @client << [v.name, v.id] }
    @project = Project.new
    if current_user.roles.first.name == 'admin'
      User.joins(:roles).where(roles: { name: 'manager' }).select(:id, :name).each { |v| @manager << [v.name, v.id] }
    else
      @manager << current_user.id
    end
  end

  def edit
    @project = Project.find(params[:id])
    params[:selected_value] = @project.client_id
    params[:selected_manager] = @project.creator_id

    @client = []
    @manager = []
    User.joins(:roles).where(roles: { name: 'customer' }).select(:id, :name).each { |v| @client << [v.name, v.id] }
    if current_user.roles.first.name == 'admin'
      User.joins(:roles).where(roles: { name: 'manager' }).select(:id, :name).each { |v| @manager << [v.name, v.id] }
    else
      @manager << current_user.id
    end
  end

  def create
    @project = Project.new(project_params)
    @project.status = 'ongoing'
    params[:selected_value] = @project.client_id
    respond_to do |format|
      if @project.save
        ProjectMailer.with(project: @project).project_created.deliver_later
        format.html { redirect_to project_url(@project), notice: 'Project was successfully created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to project_url(@project), notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def review_rating
    @project = Project.find(params[:format])
  end

  def save_review_rating
    @project = Project.find(params[:project][:id])
    respond_to do |format|
      if @project.update(project_params_review)
        format.html { redirect_to project_url(@project), notice: 'Thank You for Rating' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.destroy
    render json: { respons_message: 'Project was successfully destroyed.' }
  end

  def project_status
    @project = Project.find(params[:format])
    @project.status = params[:status] == 'true' ? 'completed' : 'ongoing'
    redirect_to action: 'show', id: @project if @project.save
  end

  private

  def set_project
    @project = Project.find_by(id: params[:id])
    redirect_to projects_path if @project.nil?
  end

  def set_project_by_format
    @project = Project.find(params[:format])
  end

  def project_params
    params.require(:project).permit(:name, :description, :client_id, :endingdate, :creator_id)
  end

  def checking_authenticity_show
    render file: 'public/403.html' unless can? :show, @project
  end

  def checking_authenticity_update
    render file: 'public/403.html' unless can? :update, @project
  end

  def checking_authenticity_status
    render file: 'public/403.html' unless can? :project_status, @project
  end

  def checking_authenticity_new
    render file: 'public/403.html' unless can? :new, Project
  end

  def project_params_review
    params.require(:project).permit(:reviews, :rating)
  end
end
