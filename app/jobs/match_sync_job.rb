class MatchSyncJob < ApplicationJob
  queue_as :default

  def perform
    Football::MatchSynchronizer.new.call
  end
end
