class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :destroy]

  def create
    @context = current_user.contexts.find(params[:context_id])

    @chat = @context.chats.build

    if @chat.save
      redirect_to chat_path(@chat)
    else
      redirect_to context_path(@context), alert: "Impossible d'ouvrir le chat."
    end
  end

  def show
    @context = @chat.context
    @message = Message.new
    @share_url = shared_chat_url(@chat.share_token) if @chat.supports_share_token? && @chat.share_token.present?
  end

  def destroy
    context = @chat.context
    @chat.destroy
    redirect_to context_path(context), notice: "Assistant supprimé."
  end

  private

  def set_chat
    @chat = Chat.joins(:context).where(contexts: { user_id: current_user.id }).find(params[:id])
  end
end
