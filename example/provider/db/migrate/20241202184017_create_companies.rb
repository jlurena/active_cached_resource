class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.references :person, null: false, foreign_key: true

      t.timestamps
    end
  end
end
