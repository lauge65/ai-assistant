# Job pour générer un podcast en arrière-plan
# Évite le timeout Heroku (30s) car la génération peut prendre 1-2 minutes
class GeneratePodcastJob < ApplicationJob
  queue_as :default

  PODCAST_PROMPT = <<~PROMPT
    Rôle : Tu es un enseignant expert en pédagogie et un scénariste de podcast professionnel.
    Ton but est de transformer un cours écrit en un script de podcast audio court et captivant pour aider les élèves à réviser.
    Ce script sera utilisé pour générer un podcast éducatif avec Gemini TTS.

    Tâche : À partir du cours fourni, rédige un script de podcast sous forme de dialogue entre deux animateurs : Alex (l'enseignant qui explique) et Sam (qui pose des questions et relance).

    Structure obligatoire du podcast :
    1.	Introduction très rapide pour accrocher l'élève et annoncer le thème.
    2.	Résumé des idées essentielles du cours avec des exemples simples.
    3.	Explication simple des notions difficiles avec des exemples concrets du quotidien.
    4.	Alerte "Pièges" : Identifie 1 erreur fréquente que les élèves font souvent sur ce chapitre.
    5.	Quiz final : Pose 1 question rapide. Sam pose la question, indique qu'il laisse 3 secondes de réflexion à l'auditeur, rajoute dans le script de laisser 3 secondes de silence avant de donner la réponse.
      Puis donne la bonne réponse avec une très courte explication.

    Contraintes de style et de formatage (OBLIGATOIRE) :
    •	Longueur stricte : Le texte doit faire entre 300 et 450 mots.
    •	Format des répliques : Commence chaque réplique strictement par "Alex :" ou "Sam :". Ne mets RIEN d'autre.
    •	Zéro didascalie : N'ajoute AUCUNE indication de mise en scène (pas de crochets, pas de parenthèses du type [rires], (pause) ou [musique]).
    Le texte généré ne doit contenir que les paroles exactes qui seront prononcées.
    •	Ton oralisé : Utilise un ton clair, chaleureux, très dynamique et encourageant.
    •	Phrases courtes : Fais des phrases courtes pour que la respiration de la voix artificielle paraisse naturelle.
    •	Acronymes et chiffres : Écris les nombres ou acronymes complexes en toutes lettres pour que la voix les prononce correctement (ex: écris "dix-neuf" au lieu de "19").
    Ne lis pas les titres du cours tels quels, intègre-les naturellement dans la conversation.
    •	Le rythme doit être lent entre les dialogues pour laisser le temps à l'élève de digérer les informations, et dynamique pendant les explications pour maintenir l'attention.

  PROMPT

  def perform(podcast_script_id)
    @podcast_script = PodcastScript.find(podcast_script_id)
    @context = @podcast_script.context

    Rails.logger.info("🎙️ Début génération podcast pour context #{@context.id}")

    begin
      # Étape 1 : Générer le script texte via LLM
      Rails.logger.info("📝 Génération du script...")
      unless generate_script
        Rails.logger.error("❌ Échec génération script")
        @podcast_script.update!(status: "failed")
        return
      end
      Rails.logger.info("✅ Script généré (#{@podcast_script.content.length} caractères)")

      # Étape 2 : Générer l'audio via Gemini TTS
      Rails.logger.info("🔊 Génération de l'audio...")
      service = GeminiTtsService.new(@podcast_script)
      result = service.generate_audio

      if result[:success]
        Rails.logger.info("✅ Podcast généré avec succès !")
      else
        Rails.logger.error("❌ Échec génération audio: #{result[:error]}")
      end

    rescue StandardError => e
      Rails.logger.error("❌ Erreur job podcast: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      @podcast_script.update!(status: "failed", audio_status: "failed")
    end
  end

  private

  def generate_script
    attempts = 0
    begin
      model = attempts == 0 ? "gemini-2.5-flash" : "gemini-3.1-flash-lite-preview"
      ruby_llm_chat = RubyLLM.chat(model: model).with_instructions(instructions)

      response = @context.document.open do |temp_file|
        ruby_llm_chat.ask(
          "Génère un script de podcast à partir de ce document de cours.",
          with: { pdf: temp_file.path }
        )
      end

      @podcast_script.update!(content: response.content, status: "completed")
      Rails.logger.info("✅ Script généré (tentative #{attempts + 1}, modèle: #{model})")
      true

    rescue RubyLLM::ServiceUnavailableError, RubyLLM::RateLimitError => e
      attempts += 1
      if attempts <= 3
        delay = [0, 0, 2, 4][attempts]
        Rails.logger.warn("⚠️ Tentative #{attempts} échouée (503), retry#{delay > 0 ? " dans #{delay}s" : " immédiatement"} [gemini-3.1-flash-lite-preview]")
        sleep(delay) if delay > 0
        retry
      else
        Rails.logger.error("❌ Toutes les tentatives ont échoué: #{e.message}")
        @podcast_script.update!(status: "failed", content: "")
        false
      end

    rescue StandardError => e
      Rails.logger.error("Erreur génération script: #{e.message}")
      @podcast_script.update!(status: "failed", content: "")
      false
    end
  end

  def instructions
    [PODCAST_PROMPT, level_context, subject_context].compact.join("\n\n")
  end

  def level_context
    "Niveau du public cible : #{@context.level}."
  end

  def subject_context
    "Matière : #{@context.subject}."
  end
end
