class ContextsController < ApplicationController
  before_action :authenticate_user!

  def index
    @contexts = current_user.contexts
  end

  def new
    @context = Context.new
  end

  def create
    @context = current_user.contexts.new(context_params)
    if @context.save
      redirect_to contexts_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def context_params
    params.require(:context).permit(:title, :level, :subject, :date, :document)
  end
end
