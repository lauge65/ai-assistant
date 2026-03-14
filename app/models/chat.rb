class Chat < ApplicationRecord
  belongs_to :context
  has_many :messages, dependent: :destroy
end
