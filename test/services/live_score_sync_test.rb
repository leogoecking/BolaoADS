require "test_helper"

class LiveScoreSyncTest < ActiveSupport::TestCase
  def reset_live_sync!
    Football::LiveScoreSync.instance_variable_set(:@last_synced_at, nil)
    Football::LiveScoreSync.instance_variable_set(:@last_result, { synced_count: 0, changed_count: 0, skipped: false })
  end

  def with_match_synchronizer(replacement)
    original = Football::MatchSynchronizer
    Football.send(:remove_const, :MatchSynchronizer)
    Football.const_set(:MatchSynchronizer, replacement)
    yield
  ensure
    Football.send(:remove_const, :MatchSynchronizer)
    Football.const_set(:MatchSynchronizer, original)
  end

  setup do
    reset_live_sync!
  end

  test "reports zero changed matches when live sync does not change score state" do
    match_record(status: "scheduled", home_score: nil, away_score: nil)
    synchronizer = Class.new do
      def initialize(live_only: false)
      end

      def call
        0
      end
    end

    with_match_synchronizer(synchronizer) do
      result = Football::LiveScoreSync.call

      assert_equal 0, result[:synced_count]
      assert_equal 0, result[:changed_count]
      assert_equal false, result[:skipped]
    end
  end

  test "falls back to full sync when a previously live match leaves live endpoint" do
    game = match_record(status: "live", home_score: 1, away_score: 0)
    synchronizer = Class.new do
      def initialize(live_only: false)
        @live_only = live_only
      end

      def call
        return 0 if @live_only

        Match.where(status: "live").update_all(status: "finished", home_score: 2, away_score: 0)
        1
      end
    end

    with_match_synchronizer(synchronizer) do
      result = Football::LiveScoreSync.call
      game.reload

      assert_equal 1, result[:synced_count]
      assert_equal 1, result[:changed_count]
      assert_equal "finished", game.status
      assert_equal 2, game.home_score
    end
  end
end
