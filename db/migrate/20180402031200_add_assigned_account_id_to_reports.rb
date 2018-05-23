class AddAssignedAccountIdToReports < ActiveRecord::Migration[5.1]
  def change
    add_reference :reports, :assigned_account, null: true, default: nil, foreign_key: { on_delete: :nullify, to_table: :accounts }, index: false
  end
end
