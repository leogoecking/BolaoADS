class SpecialPrediction < ApplicationRecord
  belongs_to :user
  belongs_to :special_question

  validates :answer, presence: true
  validates :user_id, uniqueness: { scope: :special_question_id }
  validate :question_is_open

  private

  def question_is_open
    errors.add(:base, "Palpite especial encerrado") unless special_question&.open?
  end
end
