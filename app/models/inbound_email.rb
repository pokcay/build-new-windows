# frozen_string_literal: true

class InboundEmail < ApplicationRecord
  validates :from, :to, :received_at, presence: true

  scope :active,   -> { where(archived: false) }
  scope :unread,   -> { active.where(read: false) }
  scope :archived, -> { where(archived: true) }
end
