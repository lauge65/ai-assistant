require "test_helper"

class SharedChatsControllerTest < ActionDispatch::IntegrationTest
  test "shows a chat publicly with its messages" do
    user = User.create!(email: "share@example.com", password: "password")
    context = user.contexts.new(
      title: "Les volcans",
      level: "CM2",
      subject: "SVT",
      date: Date.new(2026, 3, 31)
    )
    context.save!(validate: false)

    chat = context.chats.create!
    chat.messages.create!(role: "user", content: "Explique les volcans")
    chat.messages.create!(role: "assistant", content: "Un volcan libere du magma depuis l'interieur de la Terre.")

    get shared_chat_path(chat.share_token)

    assert_response :success
    assert_match "Chat partage", response.body
    assert_match "Explique les volcans", response.body
    assert_match "lecture seule", response.body.downcase
  end
end
