require "test_helper"

class SpecialPredictionTest < ActiveSupport::TestCase
  test "accepts answer before closing time" do
    question = SpecialQuestion.create!(key: "campeao_test", prompt: "Campeao", closes_at: 1.day.from_now)
    prediction = SpecialPrediction.new(user: user, special_question: question, answer: "Brasil")

    assert prediction.valid?
  end

  test "rejects answer after closing time" do
    question = SpecialQuestion.create!(key: "campeao_fechado_test", prompt: "Campeao", closes_at: 1.minute.ago)
    prediction = SpecialPrediction.new(user: user, special_question: question, answer: "Brasil")

    assert_not prediction.valid?
  end
end
