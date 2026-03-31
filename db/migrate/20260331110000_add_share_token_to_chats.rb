class AddShareTokenToChats < ActiveRecord::Migration[7.1]
  def up
    add_column :chats, :share_token, :string
    add_index :chats, :share_token, unique: true

    Chat.reset_column_information
    Chat.find_each do |chat|
      chat.update_columns(share_token: SecureRandom.base58(24))
    end

    change_column_null :chats, :share_token, false
  end

  def down
    remove_index :chats, :share_token
    remove_column :chats, :share_token
  end
end
