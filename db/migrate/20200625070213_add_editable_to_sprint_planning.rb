class AddEditableToSprintPlanning < ActiveRecord::Migration[5.1]
  def change
    add_column :sprint_plannings, :editable, :boolean, default: false
  end
end
