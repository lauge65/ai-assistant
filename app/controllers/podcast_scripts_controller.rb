class PodcastScriptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context

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

  # POST /contexts/:context_id/podcast_script
  def create
    # Vérifier qu'un document PDF est attaché
    unless @context.document.attached? && @context.document.content_type == "application/pdf"
      redirect_to context_path(@context), alert: "Un document PDF est requis pour générer le script."
      return
    end

    # Créer ou récupérer le podcast_script existant
    @podcast_script = @context.podcast_script || @context.build_podcast_script

    # Générer le script (appel LLM simple, sans streaming)
    if generate_script
      redirect_to context_path(@context), notice: "Le script du podcast a été généré avec succès !"
    else
      redirect_to context_path(@context), alert: "Une erreur est survenue lors de la génération du script."
    end
  end

  # GET /contexts/:context_id/podcast_script/download
  def download
    @podcast_script = @context.podcast_script

    if @podcast_script.nil? || !@podcast_script.completed?
      redirect_to context_path(@context), alert: "Le script n'est pas encore prêt."
      return
    end

    # Générer le fichier texte
    filename = "podcast_script_#{@context.title.parameterize}_#{Date.today}.txt"
    send_data @podcast_script.content,
              filename: filename,
              type: "text/plain",
              disposition: "attachment"
  end

  # POST /contexts/:context_id/podcast_script/generate_audio
  def generate_audio
    @podcast_script = @context.podcast_script

    if @podcast_script.nil? || !@podcast_script.completed?
      redirect_to context_path(@context), alert: "Le script doit d'abord être généré."
      return
    end

    # Appeler le service Gemini TTS
    service = GeminiTtsService.new(@podcast_script)
    result = service.generate_audio

    if result[:success]
      redirect_to context_path(@context), notice: "Le podcast audio a été généré avec succès !"
    else
      redirect_to context_path(@context), alert: "Erreur lors de la génération audio : #{result[:error]}"
    end
  end

  # GET /contexts/:context_id/podcast_script/download_audio
  def download_audio
    @podcast_script = @context.podcast_script

    if @podcast_script.nil? || !@podcast_script.audio_completed? || !@podcast_script.audio.attached?
      redirect_to context_path(@context), alert: "L'audio n'est pas encore prêt."
      return
    end

    # Télécharger directement le fichier depuis le service de stockage
    # Cela évite les problèmes d'accès Cloudinary (erreur 401)
    filename = "podcast_#{@context.title.parameterize}_#{Date.today}.mp3"

    send_data @podcast_script.audio.download,
              filename: filename,
              type: @podcast_script.audio.content_type,
              disposition: "attachment"
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:context_id])
  end

  def generate_script
    # Construire le chat RubyLLM (appel simple sans streaming)
    ruby_llm_chat = RubyLLM.chat(model: "gemini-2.5-flash").with_instructions(instructions)

    begin
      response = @context.document.open do |temp_file|
        ruby_llm_chat.ask(
          "Génère un script de podcast à partir de ce document de cours.",
          with: { pdf: temp_file.path }
        )
      end

      # Sauvegarder le contenu
      @podcast_script.update!(content: response.content, status: "completed")
      true

    rescue StandardError => e
      Rails.logger.error("Erreur génération podcast script: #{e.message}")
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
