class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :teams, :name, unique: true
    add_index :teams, :code, unique: true
  end
end
