class AddAdcoinsAndMatchFlags < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :adcoins_balance, :integer, null: false, default: 100

    add_column :matches, :knockout, :boolean, null: false, default: false
    add_reference :matches, :underdog_team, foreign_key: { to_table: :teams }

    add_column :predictions, :adcoins_wager, :integer, null: false, default: 0
    add_column :predictions, :adcoins_settled, :boolean, null: false, default: false

    add_index :matches, :knockout
  end
end
