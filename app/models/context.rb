class Context < ApplicationRecord
  MAX_FILE_SIZE_MB = 10
  ALLOWED_CONTENT_TYPES = ["application/pdf"].freeze
  PROGRESS_STEPS = %i[document_opened assistant_used podcast_opened summary_opened revision_completed].freeze

  belongs_to :user
  has_many :chats, dependent: :destroy
  has_one :podcast_script, dependent: :destroy

  has_one_attached :document
  has_one_attached :summary
  validates :title, :level, :subject, :date, :document, presence: true

  validate :document_size_limit
  validate :document_content_type

  include PgSearch::Model
  pg_search_scope :search_by_title_and_subject,
    against: {
      title: 'A',
      subject: 'B'
    },
    using: {
      tsearch: {
        prefix: true
      }
    }

  def progress_completed_steps
    PROGRESS_STEPS.count { |step| public_send(step) }
  end

  def progress_percentage
    ((progress_completed_steps.to_f / PROGRESS_STEPS.size) * 100).round
  end

  def progress_step_labels
    {
      document_opened: "Je découvre le cours",
      assistant_used: "J’éclaircis mes doutes avec l’assistant IA",
      podcast_opened: "J’écoute le podcast pour mieux mémoriser",
      summary_opened: "Je révise avec ma fiche de révision",
      revision_completed: "Je valide mes révisions"
    }
  end

  def all_steps_before_revision_done?
    (PROGRESS_STEPS - [:revision_completed]).all? { |step| public_send(step) }
  end

  def mark_step!(step_name)
    return unless PROGRESS_STEPS.include?(step_name.to_sym)

    update!(step_name => true)
  end

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
