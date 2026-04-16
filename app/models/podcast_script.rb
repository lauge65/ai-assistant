class PodcastScript < ApplicationRecord
  belongs_to :context, touch: true

  has_one_attached :audio

  # Statuts possibles pour le script : pending, generating, completed, failed
  validates :status, inclusion: { in: %w[pending generating completed failed] }

  # Statuts possibles pour l'audio : pending, generating, completed, failed
  validates :audio_status, inclusion: { in: %w[pending generating completed failed] }

  # Permettre le contenu vide pendant la génération (streaming)
  validates :content, presence: true, if: -> { status == "completed" }

  def pending?
    status == "pending"
  end

  def generating?
    status == "generating"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def audio_pending?
    audio_status == "pending"
  end

  def audio_generating?
    audio_status == "generating"
  end

  def audio_completed?
    audio_status == "completed"
  end

  def audio_failed?
    audio_status == "failed"
  end
end
