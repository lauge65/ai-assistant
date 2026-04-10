class User < ApplicationRecord
  LEVELS = ["CP", "CE1", "CE2", "CM1", "CM2", "6ème", "5ème", "4ème", "3ème", "Seconde", "Première", "Terminale", "Études supérieures"].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :contexts, dependent: :destroy
  has_one_attached :avatar

  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :level, inclusion: { in: LEVELS }, allow_blank: true

  def display_first_name
    first_name.presence || "toi"
  end

  def avatar_initial
    display_first_name.first.upcase
  end
end
