class ContextsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, only: [:edit, :update]

  def index
    @contexts = current_user.contexts
  end

  def show
    @context = current_user.contexts.find(params[:id])
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

  def edit
  end

  def update
    if @context.update(context_params)
      redirect_to contexts_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @context = current_user.contexts.find(params[:id])
    @context.destroy
    redirect_to contexts_path, notice: "Contexte supprimé."
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:id])
  end

  def context_params
    params.require(:context).permit(:title, :level, :subject, :date, :document)
  end
end
