module Football
  class LiveScoreSync
    MIN_INTERVAL = 60.seconds

    @last_synced_at = nil
    @last_result = { synced_count: 0, skipped: false }
    @mutex = Mutex.new

    class << self
      def call
        @mutex.synchronize do
          if @last_synced_at && @last_synced_at > MIN_INTERVAL.ago
            return @last_result.merge(skipped: true, last_synced_at: @last_synced_at)
          end

          before = score_snapshot
          had_live_matches = Match.where(status: "live").exists?
          synced_count = MatchSynchronizer.new(live_only: true).call
          synced_count += MatchSynchronizer.new.call if synced_count.zero? && had_live_matches
          changed_count = changed_matches_count(before, score_snapshot)

          @last_synced_at = Time.current
          @last_result = { synced_count: synced_count, changed_count: changed_count, skipped: false }
          @last_result.merge(last_synced_at: @last_synced_at)
        end
      end

      private

      def score_snapshot
        Match.pluck(:id, :status, :home_score, :away_score, :current_minute, :period, :live_incidents).to_h do |id, status, home_score, away_score, current_minute, period, live_incidents|
          [ id, [ status, home_score, away_score, current_minute, period, live_incidents ] ]
        end
      end

      def changed_matches_count(before, after)
        after.count do |id, state|
          before[id] != state
        end
      end
    end
  end
end
