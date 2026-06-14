class ActivityEventComment < ApplicationRecord
  belongs_to :user
  belongs_to :activity_event

  validates :body, presence: true, length: { maximum: 280 }
end
