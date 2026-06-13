require "test_helper"

class MatchMessageTest < ActiveSupport::TestCase
  test "accepts valid match message" do
    message = MatchMessage.new(user: user, match: match_record, body: "Bora virar esse jogo")

    assert message.valid?
  end

  test "rejects blank and long message" do
    player = user
    game = match_record

    blank_message = MatchMessage.new(user: player, match: game, body: "")
    long_message = MatchMessage.new(user: player, match: game, body: "a" * 281)

    assert_not blank_message.valid?
    assert_not long_message.valid?
  end
end
