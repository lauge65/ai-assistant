require "test_helper"

class PodcastScriptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "marks podcast as opened when audio is downloaded" do
    user = User.create!(email: "podcast@example.com", password: "password")
    sign_in user

    context = user.contexts.create!(
      title: "Le systeme solaire",
      level: "6e",
      subject: "Sciences",
      date: Date.new(2026, 4, 11),
      document: fixture_pdf
    )

    podcast_script = context.create_podcast_script!(status: "completed", audio_status: "completed", content: "Audio pret")
    podcast_script.audio.attach(
      io: StringIO.new("fake mp3 content"),
      filename: "podcast.mp3",
      content_type: "audio/mpeg"
    )

    get download_audio_context_podcast_script_path(context)

    assert_response :success
    assert_equal true, context.reload.podcast_opened
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
