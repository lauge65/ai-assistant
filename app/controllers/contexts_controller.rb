class ContextsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context, only: [:show, :edit, :update, :destroy]

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
    @context = current_user.contexts.find(params[:id])
    @context.destroy
    redirect_to contexts_path
  end

def generate_summary
    @context = current_user.contexts.find(params[:id])
    instructions = "Tu es un professeur expert. Rédige une fiche de révision simple, claire et structurée (sans mise en forme complexe) pour un élève de niveau #{@context.level}. La matière est #{@context.subject} et le titre du cours est '#{@context.title}'."
    ruby_llm_chat = RubyLLM.chat(model: "gemini-2.5-flash").with_instructions(instructions)
    reponse_ia = ruby_llm_chat.send_message("Rédige la fiche de révision maintenant.")
    texte_pour_la_fiche = reponse_ia.text
    pdf = Prawn::Document.new
    pdf.text "Fiche de révision : #{@context.title}", size: 24, style: :bold
    pdf.move_down 20
    pdf.text texte_pour_la_fiche, size: 12

    chemin_temporaire = Rails.root.join("tmp", "fiche_#{@context.id}.pdf")
    pdf.render_file(chemin_temporaire)

    @context.summary.attach(
      io: File.open(chemin_temporaire),
      filename: "fiche_revision_#{@context.subject.parameterize}.pdf",
      content_type: "application/pdf"
    )

    redirect_to context_path(@context), notice: "Et voilà 🎉 ! Ta fiche de révision en PDF a été créée avec succès !"
  end

  private

  def set_context
    @context = current_user.contexts.find(params[:id])
  end

  def context_params
    params.require(:context).permit(:title, :level, :subject, :date, :document)
  end
end
