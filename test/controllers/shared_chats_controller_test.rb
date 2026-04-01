require "test_helper"

class SharedChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redirects unauthenticated users to sign in" do
    user = User.create!(email: "share@example.com", password: "password")
    context = user.contexts.new(
      title: "Les volcans",
      level: "CM2",
      subject: "SVT",
      date: Date.new(2026, 3, 31)
    )
    context.save!(validate: false)

    chat = context.chats.create!

    get shared_chat_path(chat.share_token)

    assert_redirected_to new_user_session_path
  end

  test "redirects the owner to the chat when signed in" do
    user = User.create!(email: "owner@example.com", password: "password")
    sign_in user

    context = user.contexts.new(
      title: "Les volcans",
      level: "CM2",
      subject: "SVT",
      date: Date.new(2026, 3, 31)
    )
    context.save!(validate: false)

    chat = context.chats.create!

    get shared_chat_path(chat.share_token)

    assert_redirected_to chat_path(chat)
  end

  test "does not expose the shared chat to another signed in user" do
    owner = User.create!(email: "owner2@example.com", password: "password")
    intruder = User.create!(email: "intruder@example.com", password: "password")
    sign_in intruder

    context = owner.contexts.new(
      title: "Les volcans",
      level: "CM2",
      subject: "SVT",
      date: Date.new(2026, 3, 31)
    )
    context.save!(validate: false)

    chat = context.chats.create!

    get shared_chat_path(chat.share_token)

    assert_response :not_found
  end
end
