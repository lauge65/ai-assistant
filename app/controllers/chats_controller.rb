class ChatsController < ApplicationController
  before_action :authenticate_user!

  def create
    @context = current_user.contexts.find(params[:context_id])

    @chat = Chat.new(
      context: @context
    )

    if @chat.save
      redirect_to chat_path(@chat)
    else
      redirect_to context_path(@context), alert: "Impossible d'ouvrir le chat."
    end
  end

  def show
    @chat = Chat.joins(:context).where(contexts: { user_id: current_user.id }).find(params[:id])
    @context = @chat.context
    @message = Message.new
  end

  def destroy
    @chat = Chat.joins(:context).where(contexts: { user_id: current_user.id }).find(params[:id])
    @chat.destroy
    redirect_to contexts_path, notice: "Assistant supprimé."
  end
end
