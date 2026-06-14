class ActivityEventReaction < ApplicationRecord
  REACTION_TYPES = %w[kkkk cornetou zicou genio pipocou].freeze

  belongs_to :user
  belongs_to :activity_event

  validates :reaction_type, inclusion: { in: REACTION_TYPES }
  validates :user_id, uniqueness: { scope: %i[activity_event_id reaction_type] }
end
