class PredictionComment < ApplicationRecord
  belongs_to :user
  belongs_to :prediction

  validates :body, presence: true, length: { maximum: 280 }
  validate :prediction_is_revealed

  private

  def prediction_is_revealed
    errors.add(:base, "Palpite ainda nao revelado") unless prediction&.match&.predictions_revealed?
  end
end
