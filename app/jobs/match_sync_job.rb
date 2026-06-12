class MatchSyncJob < ApplicationJob
  queue_as :default

  def perform(live_only: false)
    Football::MatchSynchronizer.new(live_only: live_only).call
  end
end
