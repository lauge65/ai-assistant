class GenerateSummaryJob < ApplicationJob
  queue_as :default

  def perform(context_id)
    context = Context.find(context_id)

    return unless context.document.attached? && context.document.content_type == "application/pdf"

    instructions = "Tu es un professeur expert. Rédige une fiche de révision complète et structurée basée sur le contenu du document PDF fourni. La fiche doit être adaptée à un élève de niveau #{context.level} en #{context.subject}. Titre du cours : '#{context.title}'."

    begin
      Rails.logger.info("🚀 [Job] Appel API Gemini pour generate_summary - Context #{context.id}")
      ruby_llm_chat = RubyLLM.chat(model: "gemini-2.5-flash").with_instructions(instructions)

      texte_pour_la_fiche = nil
      context.document.open do |temp_file|
        reponse_ia = ruby_llm_chat.ask("Analyse ce document et rédige une fiche de révision complète.", with: { pdf: temp_file.path })
        texte_pour_la_fiche = reponse_ia.content
      end

      Rails.logger.info("✅ [Job] Fin appel API Gemini pour generate_summary - Context #{context.id}")
    rescue RubyLLM::RateLimitError, RubyLLM::ServiceUnavailableError, RubyLLM::ContextLengthExceededError => e
      Rails.logger.error("[Job] Gemini API indisponible pour generate_summary: #{e.message}")
      # On pourrait ajouter un statut d'erreur ici
      return
    end

    # Générer le PDF
    pdf = Prawn::Document.new
    pdf.text "Fiche de révision : #{context.title}", size: 24, style: :bold
    pdf.move_down 20
    pdf.text texte_pour_la_fiche, size: 12

    chemin_temporaire = Rails.root.join("tmp", "fiche_#{context.id}_#{Time.now.to_i}.pdf")
    pdf.render_file(chemin_temporaire)

    context.summary.attach(
      io: File.open(chemin_temporaire),
      filename: "fiche_revision_#{context.subject.parameterize}.pdf",
      content_type: "application/pdf"
    )

    # Nettoyer le fichier temporaire
    File.delete(chemin_temporaire) if File.exist?(chemin_temporaire)

    Rails.logger.info("✅ [Job] Fiche de révision créée pour Context #{context.id}")
  end
end
