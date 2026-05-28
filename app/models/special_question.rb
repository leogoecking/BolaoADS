class SpecialQuestion < ApplicationRecord
  ANSWER_TYPES = %w[text number boolean].freeze

  has_many :special_predictions, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :prompt, presence: true
  validates :answer_type, inclusion: { in: ANSWER_TYPES }
  validates :points_value, numericality: { only_integer: true, greater_than: 0 }
  validates :closes_at, presence: true

  scope :ordered, -> { order(:closes_at, :id) }

  def open?
    Time.current < closes_at
  end
end
