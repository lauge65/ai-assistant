class Context < ApplicationRecord
  belongs_to :user
  has_many :chats, depend: :destroy

  has_one_attached :document
end
