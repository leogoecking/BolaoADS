class Venue < ApplicationRecord
  has_many :matches, dependent: :nullify

  validates :external_id, :name, presence: true
  validates :external_id, uniqueness: true
end
