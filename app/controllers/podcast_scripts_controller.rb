class PodcastScriptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context

  # POST /contexts/:context_id/podcast_script
  # Lance la génération du podcast en arrière-plan
  def create
    # Vérifier qu'un document PDF est attaché
    unless @context.document.attached? && @context.document.content_type == "application/pdf"
      redirect_to context_path(@context), alert: "Un document PDF est requis pour générer le podcast."
      return
    end

    # Vérifier si un podcast est déjà en cours de génération
    if @context.podcast_script&.generating?
      redirect_to context_path(@context), notice: "La génération est déjà en cours..."
      return
    end

    # Créer ou réinitialiser le podcast_script
    @podcast_script = @context.podcast_script || @context.build_podcast_script
    @podcast_script.update!(status: "generating", audio_status: "pending", content: "")

    # Lancer le job en arrière-plan
    GeneratePodcastJob.perform_later(@podcast_script.id)

    # Réponse immédiate à l'utilisateur
    redirect_to context_path(@context), notice: "🎙️ Génération du podcast lancée ! Revenez dans 1-2 minutes."
  end

  # GET /contexts/:context_id/podcast_script/download_audio
  def download_audio
    @podcast_script = @context.podcast_script

    if @podcast_script.nil? || !@podcast_script.audio.attached?
      redirect_to context_path(@context), alert: "Le podcast n'est pas encore prêt."
      return
    end

    @context.mark_step!(:podcast_opened) unless @context.podcast_opened?

    # Télécharger directement le fichier depuis le service de stockage
    filename = "podcast_#{@context.title.parameterize}_#{Date.today}.mp3"

    send_data @podcast_script.audio.download,
              filename: filename,
              type: @podcast_script.audio.content_type,
              disposition: "attachment"
  end

  # PATCH /contexts/:context_id/podcast_script/mark_played
  def mark_played
    @context.mark_step!(:podcast_opened) unless @context.podcast_opened?
    respond_to do |format|
      format.turbo_stream
      format.any { head :ok }
    end
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:context_id])
  end
end
