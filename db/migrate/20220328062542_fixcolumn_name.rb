class FixcolumnName < ActiveRecord::Migration[7.0]
  def change
    rename_column :issues, :type, :issue_type
  end
end
