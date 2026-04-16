class Chat < ApplicationRecord
  belongs_to :context, touch: true
  has_many :messages, dependent: :destroy

  before_create :assign_share_token, if: :supports_share_token?

  def supports_share_token?
    self.class.column_names.include?("share_token")
  end

  private

  def assign_share_token
    self.share_token ||= SecureRandom.base58(24)
  end
end
