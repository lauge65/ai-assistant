class MessagesController < ApplicationController
  before_action :authenticate_user!
  include ActionView::RecordIdentifier

  SYSTEM_PROMPT = <<~PROMPT
    Tu es un assistant pédagogique.
    Tu aides un élève à comprendre un cours ou un document.
    Tu adaptes tes réponses à son niveau scolaire et à sa matière.
    Tu expliques de façon claire, simple, progressive et concise.
    Donne un exemple pour mieux comprendre.
    Maximum 3 lignes.
    Réponds en Markdown.
  PROMPT

  def create
    @chat = Chat.joins(:context).where(contexts: { user_id: current_user.id }).find(params[:chat_id])
    @context = @chat.context

    #récupérer les données du form
    user_content = message_params[:content]

    #1 enregistrer le message user
    @user_message = Message.create!(chat: @chat, role: "user", content: user_content)

    # Broadcaster immédiatement le message utilisateur
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{@chat.id}",
      target: "messages",
      partial: "messages/message",
      locals: { message: @user_message }
    )

    #2 Créer le message assistant VIDE en base AVANT l'appel LLM
    #    → indispensable pour pouvoir le broadcaster dans le bloc chunk
    @assistant_message = Message.create!(chat: @chat, role: "assistant", content: "")

    # Broadcaster immédiatement le message assistant vide (sera mis à jour par le streaming)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{@chat.id}",
      target: "messages",
      partial: "messages/message",
      locals: { message: @assistant_message }
    )


    #3 Construire le chat RubyLLM avec ruby_llm sur gemini avec un modèle capable de lire les pdf
    @ruby_llm_chat = RubyLLM.chat(model: "gemini-2.5-flash").with_instructions(instructions)
    build_conversation_history

    # 4. Appel LLM avec streaming
    accumulated_content = ""

    streaming_block = lambda do |chunk|
      next if chunk.content.blank?

      accumulated_content += chunk.content

      # Mettre à jour le contenu en mémoire (pas en base à chaque chunk = trop lent)
      @assistant_message.content = accumulated_content

      # Broadcaster le message mis à jour via ActionCable → Turbo Stream
      Turbo::StreamsChannel.broadcast_replace_to(
        "chat_#{@chat.id}",
        target: dom_id(@assistant_message),
        partial: "messages/message",
        locals: { message: @assistant_message }
      )
    end

    # lier le document à l'envoi vers le LLM
    if @context.document.attached? && @context.document.content_type == "application/pdf"
      # Télécharger le PDF via Active Storage localement (nécessaire pour Gemini, une URL ne suffit pas)
      begin
        @context.document.open do |temp_file|
          Rails.logger.info("🚀 Appel API Gemini avec PDF - Chat #{@chat.id}")
          @ruby_llm_chat.ask(user_content, with: { pdf: temp_file.path }, &streaming_block)
          Rails.logger.info("✅ Fin appel API Gemini - Chat #{@chat.id}")
        end
      rescue ActiveStorage::IntegrityError, ActiveStorage::FileNotFoundError => e
        # Si le fichier est inaccessible, répondre sans le PDF
        Rails.logger.error("Document inaccessible pour context #{@context.id}: #{e.message}")
        fallback = user_content + "\n\n(Note: Le document PDF n'est pas accessible actuellement.)"
        @ruby_llm_chat.ask(fallback, &streaming_block)
      rescue RubyLLM::ServiceUnavailableError => e
        # Rate limit ou serveur indisponible
        Rails.logger.error("Gemini API indisponible: #{e.message}")
        accumulated_content = "⚠️ Le service est temporairement surchargé. Merci de réessayer dans quelques secondes."
      end
    else
      begin
        Rails.logger.info("🚀 Appel API Gemini sans PDF - Chat #{@chat.id}")
        @ruby_llm_chat.ask(user_content, &streaming_block)
        Rails.logger.info("✅ Fin appel API Gemini - Chat #{@chat.id}")
      rescue RubyLLM::ServiceUnavailableError => e
        Rails.logger.error("Gemini API indisponible: #{e.message}")
        accumulated_content = "⚠️ Le service est temporairement surchargé. Merci de réessayer dans quelques secondes."
      end
    end

    # 5. Sauvegarder le contenu final en base (une seule écriture)
    @assistant_message.update!(content: accumulated_content)

    #6. créer une instance vide pour le prochain message
    @message = Message.new

    # 7. pour ne pas que cela remonte à chaque réponse
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end



  private
  #strong params
  def message_params
    params.require(:message).permit(:content)
  end

  # instruction du prompts
  def instructions
    [SYSTEM_PROMPT, level_context, subject_context, document_context].compact.join("\n\n")
  end

  def level_context
    "Niveau de l'élève : #{@context.level}."
  end

  def subject_context
    "Matière : #{@context.subject}."
  end

  def document_context
    return unless @context.document.attached?
    "Un document est associé à ce contexte. Son contenu détaillé pourra être exploité ensuite."
  end

  #méthode pour construire l'historique
  def build_conversation_history
    # On exclut le message assistant vide créé juste avant, il ne doit pas être dans l'historique
    @chat.messages.where.not(id: @assistant_message.id).order(:created_at).each do |message|
      @ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end
end
