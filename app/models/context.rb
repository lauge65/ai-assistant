class Context < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  has_one_attached :document
  validates :title, :level, :subject, :date, presence: true

  before_validation :set_date, on: :create

  private

  def set_date
    self.date ||= Date.today
  end
end
