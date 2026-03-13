class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :context
  has_many :messages, dependent: :destroy

  DEFAULT_TITLE = "Nouveau chat"
end
