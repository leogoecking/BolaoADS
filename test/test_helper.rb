ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  include ActiveSupport::Testing::TimeHelpers

  def user(name: "Ana", email: "ana@example.com")
    User.create!(
      name: name,
      email: email,
      password: "secret123",
      password_confirmation: "secret123"
    )
  end

  def team(name:, code:)
    Team.create!(name: name, code: code)
  end

  def match_record(kickoff_at: 1.hour.from_now, status: "scheduled", home_score: nil, away_score: nil)
    Match.create!(
      external_id: SecureRandom.uuid,
      home_team: team(name: "Brasil #{SecureRandom.hex(2)}", code: "BRA#{SecureRandom.hex(2).upcase}"),
      away_team: team(name: "Argentina #{SecureRandom.hex(2)}", code: "ARG#{SecureRandom.hex(2).upcase}"),
      kickoff_at: kickoff_at,
      status: status,
      home_score: home_score,
      away_score: away_score
    )
  end
end
