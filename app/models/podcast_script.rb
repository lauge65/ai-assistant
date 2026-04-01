class PodcastScript < ApplicationRecord
  belongs_to :context

  # Statuts possibles : pending, generating, completed, failed
  validates :status, inclusion: { in: %w[pending generating completed failed] }

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
end
