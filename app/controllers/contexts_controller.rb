class ContextsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, only: [:show, :edit, :update, :destroy]

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
    @context =current_user.contexts.new(context_params)
    if @context.save
      chat = @context.chats.create!
      redirect_to chat_path(chat),
        notice: "Bravo 🎉 Tu peux discuter avec ton assistant pour réviser ton cours de #{@context.subject}"
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
    @context = current_user.contexts.find(params[:id])
    @context.destroy
    redirect_to contexts_path
  end

  def generate_summary
    @context = current_user.contexts.find(params[:id])
    texte_pour_la_fiche = "Voici la fiche de révision pour le cours de #{@context.subject}.\n\n(Le texte généré par l'Intelligence Artificielle arrivera ici !)"
    pdf = Prawn::Document.new
    pdf.text "Fiche de révision : #{@context.title}", size: 24, style: :bold
    pdf.move_down 20 # On saute une ligne
    pdf.text texte_pour_la_fiche, size: 12
    chemin_temporaire = Rails.root.join("tmp", "fiche_#{@context.id}.pdf")
    pdf.render_file(chemin_temporaire)

    @context.summary.attach(
      io: File.open(chemin_temporaire),
      filename: "fiche_revision_#{@context.subject.parameterize}.pdf",
      content_type: "application/pdf"
      )

    redirect_to context_path(@context), notice: "Et voilà 🎉 ! Ta fiche de révision en PDF a été crée avec succès !"
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:id])
  end

  def context_params
    params.require(:context).permit(:title, :level, :subject, :date, :document)
  end
end
