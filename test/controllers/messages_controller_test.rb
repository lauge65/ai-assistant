require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "marks assistant as used after first message" do
    user = User.create!(email: "messages@example.com", password: "password")
    sign_in user

    context = user.contexts.create!(
      title: "Les fractions",
      level: "6e",
      subject: "Maths",
      date: Date.new(2026, 4, 11),
      document: fixture_pdf
    )
    chat = context.chats.create!

    fake_chat = FakeRubyLlmChat.new
    fake_chunk = Struct.new(:content).new("Reponse courte")

    RubyLLM.stub :chat, fake_chat do
      post chat_messages_path(chat), params: { message: { content: "Explique moi les fractions" } }
    end

    assert_redirected_to chat_path(chat)
    assert_equal true, context.reload.assistant_used
    assert_equal 2, chat.messages.count
    assert_equal "Reponse courte", chat.messages.order(:created_at).last.content
  end

  private

  def fixture_pdf
    {
      io: StringIO.new("%PDF-1.4 test pdf"),
      filename: "cours.pdf",
      content_type: "application/pdf"
    }
  end

  class FakeRubyLlmChat
    def with_instructions(_instructions)
      self
    end

    def add_message(**_args); end

    def ask(_content, with: nil)
      yield Struct.new(:content).new("Reponse courte")
    end
  end
end
