class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :document_type
      t.date :expiration_date

      t.timestamps
    end
  end
end
