class Reminder < ApplicationRecord
  belongs_to :document

  validates :send_at, presence: true
  validates :sent, inclusion: { in: [true, false] }
end
