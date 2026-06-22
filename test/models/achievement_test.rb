require "test_helper"

class AchievementTest < ActiveSupport::TestCase
  test "unlocks last minute achievement between twenty and ten minutes" do
    player = user
    game = match_record(kickoff_at: 15.minutes.from_now)

    travel_to(game.kickoff_at - 15.minutes) do
      Prediction.create!(user: player, match: game, home_score: 1, away_score: 0)
    end

    assert_includes player.achievements.pluck(:key), "ultima_hora"
  end

  test "unlocks mae dina after three exact scores" do
    player = user

    3.times do
      game = match_record(kickoff_at: 1.day.from_now)
      Prediction.create!(user: player, match: game, home_score: 2, away_score: 1)
      game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 1)
    end

    assert_includes player.achievements.pluck(:key), "mae_dina"
  end

  test "unlocks group stage marathon after thirty group predictions" do
    player = user

    30.times do |index|
      game = Match.create!(
        external_id: "group-marathon-#{index}",
        home_team: team(name: "Casa #{index}", code: "CASA#{index}"),
        away_team: team(name: "Fora #{index}", code: "FORA#{index}"),
        kickoff_at: 1.day.from_now,
        status: "scheduled",
        stage: "Fase de grupos"
      )
      Prediction.create!(user: player, match: game, home_score: 1, away_score: 0)
    end

    assert_includes player.achievements.pluck(:key), "maratonista_grupos"
  end

  test "unlocks full day achievement when user predicts all matches from a day" do
    player = user
    kickoff_day = Date.new(2026, 6, 25)
    games = [
      match_record(kickoff_at: kickoff_day.to_time.change(hour: 13)),
      match_record(kickoff_at: kickoff_day.to_time.change(hour: 16)),
      match_record(kickoff_at: kickoff_day.to_time.change(hour: 19))
    ]

    games.each { |game| Prediction.create!(user: player, match: game, home_score: 1, away_score: 0) }

    assert_includes player.achievements.pluck(:key), "nao_dormiu_no_ponto"
  end

  test "unlocks all in achievement when large wager scores points" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    Prediction.create!(user: player, match: game, home_score: 2, away_score: 1, adcoins_wager: 100)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 0)

    assert_includes player.achievements.pluck(:key), "all_in_consciente"
  end

  test "unlocks frustration achievement after ten finished misses" do
    player = user

    10.times do
      game = match_record(kickoff_at: 1.day.from_now)
      Prediction.create!(user: player, match: game, home_score: 1, away_score: 0)
      game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 0, away_score: 1)
    end

    assert_includes player.achievements.pluck(:key), "so_passou_raiva"
  end

  test "unlocks knockout survivor after any knockout hit" do
    player = user
    game = match_record(kickoff_at: 1.day.from_now)
    game.update!(knockout: true)
    Prediction.create!(user: player, match: game, home_score: 1, away_score: 0)

    game.update!(kickoff_at: 1.day.ago, status: "finished", home_score: 2, away_score: 0)

    assert_includes player.achievements.pluck(:key), "sobreviveu_mata_mata"
  end

  test "unlocks betting magnate for user with most adcoins" do
    leader = user(name: "Lider", email: "lider@example.com")
    user(name: "Rival", email: "rival@example.com").update!(adcoins_balance: 150)
    leader.update!(adcoins_balance: 300)

    AchievementUnlocker.new(leader).call

    assert_includes leader.achievements.pluck(:key), "magnata_do_palpite"
  end

  test "refreshes betting magnate when adcoins leader changes after wager" do
    leader = user(name: "Lider", email: "lider@example.com")
    new_leader = user(name: "Novo Lider", email: "novo@example.com")
    leader.update!(adcoins_balance: 300)
    new_leader.update!(adcoins_balance: 250)
    game = match_record(kickoff_at: 1.day.from_now)

    Prediction.create!(user: leader, match: game, home_score: 1, away_score: 0, adcoins_wager: 100)

    assert_includes new_leader.achievements.pluck(:key), "magnata_do_palpite"
  end

  test "unlocks fake millionaire after one thousand adcoins" do
    player = user
    player.update!(adcoins_balance: 1_000)

    AchievementUnlocker.new(player).call

    assert_includes player.achievements.pluck(:key), "milionario_de_mentira"
  end
end
