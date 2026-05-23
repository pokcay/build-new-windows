# frozen_string_literal: true

class EmailTemplate < ApplicationRecord
  belongs_to :updated_by, class_name: "User", optional: true

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :subject, presence: true
end
