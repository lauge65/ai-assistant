class MessagesController < ApplicationController
  before_action :authenticate_user!

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

    # pour lancer ruby_llm sur gemini avec un modèle capable de lire les pdf
    @ruby_llm_chat = RubyLLM.chat(model: "gemini-2.5-flash").with_instructions(instructions)
    build_conversation_history

    # enregistrer le message user
    @user_message = Message.create!(
      chat: @chat,
      role: "user",
      content: user_content
      )

    # lier le document à l'envoi vers le LLM
    response = if @context.document.attached? && @context.document.content_type == "application/pdf"
      # Télécharger le PDF dans un fichier temporaire pour éviter les problèmes d'auth Cloudinary
      temp_file = Tempfile.new(['document', '.pdf'])
      begin
        temp_file.binmode
        @context.document.download { |chunk| temp_file.write(chunk) }
        temp_file.rewind
        @ruby_llm_chat.ask(user_content, with: { pdf: temp_file.path })
      ensure
        temp_file.close
        temp_file.unlink
      end
    else
      @ruby_llm_chat.ask(user_content)
    end

    #enregitrer le message assistant ia
    @assistant_message = Message.create!(
      chat: @chat,
      role: "assistant",
      content: response.content
    )

    #créer une instance vide pour le prochain message
    @message = Message.new

    # pour ne pas que cela remonte à chaque réponse
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
    [
      SYSTEM_PROMPT,
      level_context,
      subject_context,
      document_context
    ].compact.join("\n\n")
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
    @chat.messages.order(:created_at).each do |message|
      @ruby_llm_chat.add_message(
        role: message.role,
        content: message.content
      )
    end
  end
end


# Ancien code que j'ai modifié pour mettre en place l'historique du chat
    # @message = Message.new(message_params)
    # @message.chat = @chat
    # @message.role = "user"

  #   if @message.save
  #     @ruby_llm_chat = RubyLLM.chat
  #     build_conversation_history
  #     response = @ruby_llm_chat.with_instructions(instructions).ask(@message.content)

  #     Message.create!(
  #       chat: @chat,
  #       role: "assistant",
  #       content: response.content
  #     )

  #     redirect_to chat_path(@chat)
  #   else
  #     render "chats/show", status: :unprocessable_entity
  #   end
  # end
