class Message < ApplicationRecord
  belongs_to :chat

  validates :role, inclusion: { in: %w[user assistant] }
end
