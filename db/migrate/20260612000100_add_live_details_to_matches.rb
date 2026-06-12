class AddLiveDetailsToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :current_minute, :integer
    add_column :matches, :period, :string
    add_column :matches, :live_incidents, :text, default: "[]", null: false
    add_column :matches, :live_incidents_synced_at, :datetime
  end
end
