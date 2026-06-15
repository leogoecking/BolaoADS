class CreateVenues < ActiveRecord::Migration[8.0]
  def change
    create_table :venues do |t|
      t.string :external_id, null: false
      t.string :name, null: false
      t.string :city
      t.string :country
      t.integer :capacity

      t.timestamps
    end

    add_index :venues, :external_id, unique: true
  end
end
