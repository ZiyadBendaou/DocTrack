class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  has_many :reminders, dependent: :destroy

  validates :document_type, presence: true, length: { maximum: 40 }
  validates :expiration_date, presence: true
  validates :reminder_days,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :expiration_date_cannot_be_in_the_past
  validate :file_type_and_size

  private

  def expiration_date_cannot_be_in_the_past
    return if expiration_date.blank?
    if expiration_date < Date.today
      errors.add(:expiration_date, "can't be in the past")
    end
  end

  def file_type_and_size
    return unless file.attached?

    if !file.content_type.start_with?("image/")
      errors.add(:file, "must be an image")
    elsif file.blob.byte_size > 5.megabytes
      errors.add(:file, "size must be under 5MB")
    end
  end
end
