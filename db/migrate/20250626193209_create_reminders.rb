class CreateReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :reminders do |t|
      t.references :document, null: false, foreign_key: true
      t.datetime :send_at
      t.boolean :sent

      t.timestamps
    end
  end
end
