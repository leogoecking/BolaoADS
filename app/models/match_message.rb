class MatchMessage < ApplicationRecord
  belongs_to :user
  belongs_to :match

  validates :body, presence: true, length: { maximum: 280 }

  scope :oldest_first, -> { order(:created_at, :id) }
  scope :latest_window, ->(limit = 60) { order(created_at: :desc, id: :desc).limit(limit) }
end
