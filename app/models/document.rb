class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  has_many :reminders, dependent: :destroy

  validates :document_type, presence: true, length: { maximum: 40 }
  validates :expiration_date, presence: true
  validate  :expiry_date_cannot_be_in_the_past

  def expiry_date_cannot_be_in_the_past
    return if expiration_date.blank?
    if expiration_date < Date.today
      errors.add(:expiration_date, "can't be in the past")
    end
  end
end
