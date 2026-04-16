class Message < ApplicationRecord
  MAX_USER_MESSAGES = 30
  belongs_to :chat, touch: true

  validates :role, inclusion: { in: %w[user assistant] }
  # Permettre le contenu vide pour les messages assistant (streaming)
  validates :content, presence: true, if: -> { role == "user" }

  validate :user_message_limit, if: -> { role == "user" }

  private

  def user_message_limit
    if chat.messages.where(role: "user").count >= MAX_USER_MESSAGES
      errors.add(:content, "You can only send #{MAX_USER_MESSAGES} messages per chat.")
    end
  end

end
