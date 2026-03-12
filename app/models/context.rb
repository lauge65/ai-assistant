class Context < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  has_one_attached :document
  validates :title, :level, :subject, :date, presence: true
  validate :document_must_be_attached

  private

  def document_must_be_attached
    unless document.attached?
      errors.add(:document, "must be attached")
    end
  end

end
