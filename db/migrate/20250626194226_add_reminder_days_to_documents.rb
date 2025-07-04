class AddReminderDaysToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :reminder_days, :integer
  end
end
