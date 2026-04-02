# Service pour générer un podcast audio à partir d'un script via Gemini TTS
# Utilise l'API Gemini 2.5 Flash Preview TTS avec multi-speaker
class GeminiTtsService
  GEMINI_TTS_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent"

  def initialize(podcast_script)
    @podcast_script = podcast_script
    @api_key = ENV["GEMINI_API_KEY"]
  end

  def generate_audio
    return { success: false, error: "Script non complété" } unless @podcast_script.completed?
    return { success: false, error: "Clé API Gemini manquante" } if @api_key.blank?

    @podcast_script.update!(audio_status: "generating")

    begin
      response = call_gemini_tts

      if response[:success]
        save_audio(response[:audio_data])

        # Vérifier que l'audio a bien été attaché
        if @podcast_script.audio.attached?
          @podcast_script.update!(audio_status: "completed")
          { success: true }
        else
          @podcast_script.update!(audio_status: "failed")
          { success: false, error: "Échec de l'attachement du fichier audio" }
        end
      else
        @podcast_script.update!(audio_status: "failed")
        { success: false, error: response[:error] }
      end
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      Rails.logger.error("Timeout Gemini TTS: #{e.message}")
      @podcast_script.update!(audio_status: "failed")
      { success: false, error: "La génération audio a pris trop de temps. Veuillez réessayer." }
    rescue StandardError => e
      Rails.logger.error("Erreur Gemini TTS: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))

      # Si l'audio a quand même été attaché malgré l'erreur, on considère que c'est un succès
      if @podcast_script.audio.attached?
        @podcast_script.update!(audio_status: "completed")
        Rails.logger.info("Audio attaché malgré l'erreur - marqué comme completed")
        { success: true }
      else
        @podcast_script.update!(audio_status: "failed")
        { success: false, error: e.message }
      end
    end
  end

  private

  def call_gemini_tts
    uri = URI("#{GEMINI_TTS_URL}?key=#{@api_key}")

    request_body = {
      contents: [
        {
          parts: [
            { text: @podcast_script.content }
          ]
        }
      ],
      generationConfig: {
        responseModalities: ["AUDIO"],
        speechConfig: {
          multiSpeakerVoiceConfig: {
            speakerVoiceConfigs: [
              {
                speaker: "Alex",
                voiceConfig: {
                  prebuiltVoiceConfig: { voiceName: "Charon" }
                }
              },
              {
                speaker: "Sam",
                voiceConfig: {
                  prebuiltVoiceConfig: { voiceName: "Kore" }
                }
              }
            ]
          }
        }
      }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30      # 30 secondes pour établir la connexion
    http.read_timeout = 300     # 5 minutes pour la génération audio (peut être long)
    http.write_timeout = 60     # 1 minute pour envoyer la requête

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    Rails.logger.info("Appel Gemini TTS - Script de #{@podcast_script.content.length} caractères")

    response = http.request(request)

    Rails.logger.info("Réponse Gemini TTS reçue - Code: #{response.code}")

    if response.code == "200"
      parse_audio_response(response.body)
    else
      Rails.logger.error("Gemini TTS API error: #{response.code} - #{response.body}")
      { success: false, error: "Erreur API: #{response.code}" }
    end
  end

  def parse_audio_response(response_body)
    data = JSON.parse(response_body)

    # L'audio est retourné en base64 dans la réponse
    audio_part = data.dig("candidates", 0, "content", "parts", 0)

    if audio_part && audio_part["inlineData"]
      audio_base64 = audio_part["inlineData"]["data"]
      mime_type = audio_part["inlineData"]["mimeType"] || "audio/L16"

      Rails.logger.info("Format audio reçu: #{mime_type}")

      audio_data = Base64.decode64(audio_base64)
      { success: true, audio_data: audio_data, mime_type: mime_type }
    else
      Rails.logger.error("Réponse Gemini TTS inattendue: #{data}")
      { success: false, error: "Format de réponse inattendu" }
    end
  end

  def save_audio(audio_data)
    # Gemini TTS retourne du PCM brut (audio/L16) à 24kHz, 16-bit, mono
    # On convertit en MP3 (~1.5 Mo) pour respecter la limite Cloudinary de 10 Mo

    pcm_file = Tempfile.new(["podcast_pcm", ".raw"])
    mp3_file = Tempfile.new(["podcast_mp3", ".mp3"])

    begin
      # Écrire les données PCM brutes
      pcm_file.binmode
      pcm_file.write(audio_data)
      pcm_file.close

      Rails.logger.info("Fichier PCM créé: #{pcm_file.path} (#{File.size(pcm_file.path)} bytes)")

      # Convertir PCM → MP3 avec FFmpeg
      if convert_pcm_to_mp3(pcm_file.path, mp3_file.path)
        Rails.logger.info("Fichier MP3 créé: #{mp3_file.path} (#{File.size(mp3_file.path)} bytes)")

        # Supprimer l'ancien audio s'il existe
        @podcast_script.audio.purge if @podcast_script.audio.attached?

        # Attacher le fichier MP3
        filename = "podcast_#{@podcast_script.context.title.parameterize}_#{Time.current.to_i}.mp3"

        @podcast_script.audio.attach(
          io: File.open(mp3_file.path, 'rb'),
          filename: filename,
          content_type: "audio/mpeg"
        )
      else
        raise "Échec de la conversion audio → MP3"
      end
    ensure
      pcm_file.close unless pcm_file.closed?
      pcm_file.unlink
      mp3_file.close unless mp3_file.closed?
      mp3_file.unlink
    end
  rescue StandardError => e
    Rails.logger.error("Erreur sauvegarde audio: #{e.message}")
    raise e
  end

  def convert_pcm_to_mp3(pcm_path, mp3_path)
    # Gemini TTS retourne du PCM brut:
    # - Format: signed 16-bit little-endian (s16le)
    # - Sample rate: 24000 Hz
    # - Channels: 1 (mono)
    #
    # FFmpeg options:
    # -f s16le : format d'entrée PCM signed 16-bit little-endian
    # -ar 24000 : sample rate d'entrée 24 kHz
    # -ac 1 : 1 canal (mono)
    # -i : fichier d'entrée
    # -b:a 128k : bitrate MP3 128 kbps
    command = "ffmpeg -y -f s16le -ar 24000 -ac 1 -i #{pcm_path.shellescape} -b:a 128k #{mp3_path.shellescape} 2>&1"

    Rails.logger.info("Conversion FFmpeg: #{command}")

    output = `#{command}`
    success = $?.success?

    unless success
      Rails.logger.error("Erreur FFmpeg: #{output}")
    end

    success
  end
end
