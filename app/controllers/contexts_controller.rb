class ContextsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, only: [:show, :edit, :update, :destroy, :generate_summary, :open_document, :open_summary, :complete_revision, :lecture, :mark_document_read, :lecture_summary, :mark_summary_read]

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

  def open_document
    unless @context.document.attached?
      return redirect_to context_path(@context), alert: "⚠️ Aucun PDF attaché à ce cours."
    end

    @context.mark_step!(:document_opened)
    redirect_to rails_blob_url(@context.document, disposition: "inline")
  end

  def lecture
    unless @context.document.attached?
      return redirect_to context_path(@context), alert: "⚠️ Aucun PDF attaché à ce cours."
    end

    @context.mark_step!(:document_opened)
    @pdf_url = rails_blob_url(@context.document, disposition: "inline")
  end

  def mark_document_read
    @context.mark_step!(:document_opened)
    render json: { ok: true }
  end

  def lecture_summary
    unless @context.summary.attached?
      return redirect_to context_path(@context), alert: "⚠️ Aucune fiche disponible."
    end

    @context.mark_step!(:summary_opened)
    @pdf_url = rails_blob_url(@context.summary, disposition: "inline")
  end

  def mark_summary_read
    @context.mark_step!(:summary_opened)
    render json: { ok: true }
  end

  def complete_revision
    unless @context.all_steps_before_revision_done?
      return redirect_to context_path(@context),
        alert: "Tu n'as pas encore terminé toutes les étapes ! Ouvre ton cours, utilise l'assistant, écoute le podcast et lis ta fiche de révision."
    end

    @context.mark_step!(:revision_completed)
    redirect_to context_path(@context),
      notice: "Bravo ! Tu as terminé toutes les étapes de révision 🎉",
      flash: { confetti: true }
  end

  def open_summary
    unless @context.summary.attached?
      return redirect_to context_path(@context), alert: "⚠️ Aucune fiche de revision disponible pour ce cours."
    end

    @context.mark_step!(:summary_opened)
    redirect_to rails_blob_url(@context.summary, disposition: "attachment")
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:id])
  end

  def context_params
    params.require(:context).permit(:title, :level, :subject, :date, :document)
  end
end
