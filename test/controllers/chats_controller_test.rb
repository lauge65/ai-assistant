require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "shows the sharing tools for a generated chat" do
    user = User.create!(email: "owner@example.com", password: "password")
    sign_in user

    context = user.contexts.new(
      title: "Les fractions",
      level: "6e",
      subject: "Maths",
      date: Date.new(2026, 3, 31)
    )
    context.save!(validate: false)

    chat = context.chats.create!
    chat.messages.create!(role: "user", content: "C'est quoi une fraction ?")
    chat.messages.create!(role: "assistant", content: "Une fraction represente une partie d'un tout.")

    get chat_path(chat)

    assert_response :success
    assert_match "Partager ce chat", response.body
    assert_match shared_chat_url(chat.share_token), response.body
    assert_match "api.qrserver.com", response.body
  end
end
