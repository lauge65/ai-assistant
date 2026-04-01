class SharedChatsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    raise ActiveRecord::RecordNotFound unless Chat.column_names.include?("share_token")

    @chat = Chat.includes(:messages, :context).find_by!(share_token: params[:share_token])
    @context = @chat.context
  end
end
