require "test_helper"

class ActivityEventGeneratorTest < ActiveSupport::TestCase
  test "creates exact score and leader changed events when match is settled" do
    ana = user(name: "Ana", email: "ana@example.com")
    maria = user(name: "Maria", email: "maria@example.com")
    game = match_record(kickoff_at: 1.day.from_now)

    Prediction.create!(user: ana, match: game, home_score: 0, away_score: 0)
    Prediction.create!(user: maria, match: game, home_score: 2, away_score: 1)

    assert_difference "ActivityEvent.count", 2 do
      game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)
    end

    assert ActivityEvent.exists?(event_type: "exact_score", user: maria)
    assert ActivityEvent.exists?(event_type: "leader_changed", user: maria)
  end

  test "does not duplicate events when match is processed again" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)

    assert_no_difference "ActivityEvent.count" do
      game.score_predictions
    end
  end

  test "creates ranking drop event for three or more lost positions" do
    leandro = user(name: "Leandro", email: "leandro@example.com")
    ana = user(name: "Ana", email: "ana@example.com")
    bia = user(name: "Bia", email: "bia@example.com")
    carla = user(name: "Carla", email: "carla@example.com")
    previous_ranking = [leandro, ana, bia, carla]

    [ana, bia, carla].each do |player|
      game = match_record(kickoff_at: 1.day.from_now)
      Prediction.create!(user: player, match: game, home_score: 1, away_score: 0).update_columns(points: 3)
    end

    finished_game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: leandro, match: finished_game, home_score: 3, away_score: 0)
    finished_game.update_columns(kickoff_at: 1.day.ago, status: "finished", home_score: 0, away_score: 1)

    ActivityEventGenerator.new(finished_game, previous_ranking: previous_ranking).call

    event = ActivityEvent.find_by(event_type: "ranking_drop", user: leandro)
    assert event
    assert_includes event.message, "perdeu 3 posicoes"
  end
end
