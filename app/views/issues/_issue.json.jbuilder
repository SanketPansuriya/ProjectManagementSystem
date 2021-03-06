# frozen_string_literal: true

json.extract! issue, :id, :project_id, :title, :description, :type, :status, :employee_id, :created_at, :updated_at
json.url issue_url(issue, format: :json)
