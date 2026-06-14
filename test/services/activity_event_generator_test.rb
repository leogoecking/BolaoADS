require "test_helper"

class ActivityEventGeneratorTest < ActiveSupport::TestCase
  test "creates exact score and leader changed events when match is settled" do
    ana = user(name: "Ana", email: "ana@example.com")
    maria = user(name: "Maria", email: "maria@example.com")
    game = match_record(kickoff_at: 1.day.from_now)

    Prediction.create!(user: ana, match: game, home_score: 0, away_score: 0)
    Prediction.create!(user: maria, match: game, home_score: 2, away_score: 1)

    assert_difference "ActivityEvent.count", 4 do
      game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)
    end

    assert ActivityEvent.exists?(event_type: "exact_score", user: maria)
    assert ActivityEvent.exists?(event_type: "leader_changed", user: maria)
    assert ActivityEvent.exists?(event_type: "only_believer", user: maria)
    assert ActivityEvent.exists?(event_type: "big_climb", user: maria)
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

  test "creates no hits event when nobody nails exact score" do
    ana = user(name: "Ana", email: "ana@example.com")
    bia = user(name: "Bia", email: "bia@example.com")
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: ana, match: game, home_score: 1, away_score: 0)
    Prediction.create!(user: bia, match: game, home_score: 0, away_score: 0)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)

    event = ActivityEvent.find_by(event_type: "no_hits")
    assert event
    assert_includes event.message, "Ninguem cravou"
  end

  test "creates underdog hit event for users who backed the zebra" do
    home = team(name: "Favorito", code: "FAV")
    away = team(name: "Zebra", code: "ZEB")
    player = user(name: "Bia", email: "bia@example.com")
    game = Match.create!(
      external_id: SecureRandom.uuid,
      home_team: home,
      away_team: away,
      underdog_team: away,
      kickoff_at: 1.day.from_now,
      status: "scheduled"
    )
    Prediction.create!(user: player, match: game, home_score: 0, away_score: 1)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 0, away_score: 1)

    event = ActivityEvent.find_by(event_type: "underdog_hit", user: player)
    assert event
    assert_includes event.message, "acreditou na zebra"
  end
end
