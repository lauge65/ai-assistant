require "test_helper"

class ContextsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "marks document as opened before redirecting to pdf" do
    user = User.create!(email: "context@example.com", password: "password")
    sign_in user

    context = user.contexts.create!(
      title: "Les fractions",
      level: "6e",
      subject: "Maths",
      date: Date.new(2026, 4, 11),
      document: fixture_pdf
    )

    get open_document_context_path(context)

    assert_response :redirect
    assert_equal true, context.reload.document_opened
  end

  test "marks revision as completed" do
    user = User.create!(email: "revision@example.com", password: "password")
    sign_in user

    context = user.contexts.create!(
      title: "Les verbes",
      level: "5e",
      subject: "Francais",
      date: Date.new(2026, 4, 11),
      document: fixture_pdf
    )

    patch complete_revision_context_path(context)

    assert_redirected_to context_path(context)
    assert_equal true, context.reload.revision_completed
  end

  test "marks summary as opened before downloading it" do
    user = User.create!(email: "summary@example.com", password: "password")
    sign_in user

    context = user.contexts.create!(
      title: "La poesie",
      level: "4e",
      subject: "Francais",
      date: Date.new(2026, 4, 11),
      document: fixture_pdf
    )
    context.summary.attach(fixture_pdf)

    get open_summary_context_path(context)

    assert_response :redirect
    assert_equal true, context.reload.summary_opened
  end

  private

  def fixture_pdf
    {
      io: StringIO.new("%PDF-1.4 test pdf"),
      filename: "cours.pdf",
      content_type: "application/pdf"
    }
  end
end
