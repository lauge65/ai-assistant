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

    user_content = message_params[:content]

    @ruby_llm_chat = RubyLLM.chat.with_instructions(instructions)
    build_conversation_history

    response = @ruby_llm_chat.ask(user_content)

    Message.create!(
    chat: @chat,
    role: "user",
    content: user_content
  )

    Message.create!(
      chat: @chat,
      role: "assistant",
      content: response.content
    )

    redirect_to chat_path(@chat)

  end



  private

  def message_params
    params.require(:message).permit(:content)
  end

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
