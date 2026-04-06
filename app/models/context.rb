class Context < ApplicationRecord
  MAX_FILE_SIZE_MB = 10
  ALLOWED_CONTENT_TYPES = ["application/pdf"].freeze

  belongs_to :user
  has_many :chats, dependent: :destroy
  has_one :podcast_script, dependent: :destroy

  has_one_attached :document
  has_one_attached :summary
  validates :title, :level, :subject, :date, :document, presence: true

  validate :document_size_limit
  validate :document_content_type

  private

  def document_size_limit
    if document.attached? && document.byte_size > MAX_FILE_SIZE_MB.megabytes
      errors.add(:document, "doit faire moins de #{MAX_FILE_SIZE_MB} Mo")
    end
  end

  def document_content_type
    if document.attached? && !document.content_type.in?(ALLOWED_CONTENT_TYPES)
      errors.add(:document, "doit être un fichier PDF")
    end
  end

end
