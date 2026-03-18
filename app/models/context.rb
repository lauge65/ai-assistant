class Context < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  has_one_attached :document
  validates :title, :level, :subject, :date, :document, presence: true
end
