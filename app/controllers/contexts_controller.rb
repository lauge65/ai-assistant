class ContextsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, only: [:show, :edit, :update, :destroy, :generate_summary]

  def index
    @contexts = current_user.contexts

    if params[:query].present?
      @contexts = @contexts.search_by_title_and_subject(params[:query])
    end
  end

  def show
    @context = current_user.contexts.find(params[:id])
  end

  def new
    @context = current_user.contexts.new(level: current_user.level)
  end

  def create
    @context =current_user.contexts.new(context_params)
    if @context.save
      @context.chats.create!
      redirect_to contexts_path,
        notice: "Bravo 🎉 Ton cours #{@context.title} a été importé avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
     @context
  end

  def update
    if @context.update(context_params)
      redirect_to context_path(@context)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @context.destroy
    redirect_to contexts_path
  end

  def generate_summary
    unless @context.document.attached? && @context.document.content_type == "application/pdf"
      return redirect_to context_path(@context), alert: "⚠️ Aucun PDF attaché à ce cours."
    end

    # Lancer la génération en arrière-plan
    GenerateSummaryJob.perform_later(@context.id)

    redirect_to context_path(@context), notice: "📝 La fiche de révision est en cours de génération. Reviens dans quelques secondes !"
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:id])
  end

  def context_params
    params.require(:context).permit(:title, :level, :subject, :date, :document)
  end
end
