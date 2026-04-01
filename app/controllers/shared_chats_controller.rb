class SharedChatsController < ApplicationController
  def show
    raise ActiveRecord::RecordNotFound unless Chat.column_names.include?("share_token")

    @chat = Chat.joins(:context).where(contexts: { user_id: current_user.id }).find_by!(share_token: params[:share_token])

    redirect_to chat_path(@chat)
  end
end
