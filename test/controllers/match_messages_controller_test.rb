require "test_helper"

class MatchMessagesControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated user" do
    game = match_record

    get match_messages_path(game)

    assert_redirected_to new_session_path
  end

  test "creates message for authenticated user" do
    player = user
    game = match_record

    post session_path, params: { email: player.email, password: "secret123" }

    assert_difference "MatchMessage.count", 1 do
      post match_messages_path(game), params: { match_message: { body: "Que jogo" } }
    end

    assert_redirected_to match_path(game, anchor: "resenha")
    assert_equal "Que jogo", game.match_messages.last.body
    assert_equal player, game.match_messages.last.user
  end

  test "lists only messages for the requested match" do
    player = user
    game = match_record
    other_game = match_record
    MatchMessage.create!(user: player, match: game, body: "Daqui")
    MatchMessage.create!(user: player, match: other_game, body: "De outro jogo")

    post session_path, params: { email: player.email, password: "secret123" }
    get match_messages_path(game)

    assert_response :success
    assert_includes response.body, "Daqui"
    assert_not_includes response.body, "De outro jogo"
  end

  test "xhr create returns updated message list" do
    player = user
    game = match_record

    post session_path, params: { email: player.email, password: "secret123" }

    assert_difference "MatchMessage.count", 1 do
      post match_messages_path(game),
        params: { match_message: { body: "Ao vivo demais" } },
        headers: { "X-Requested-With" => "XMLHttpRequest" }
    end

    assert_response :created
    assert_includes response.body, "Ao vivo demais"
  end
end
