class GenerateSummaryJob < ApplicationJob
  queue_as :default

  def perform(context_id)
    context = Context.find(context_id)

    return unless context.document.attached? && context.document.content_type == "application/pdf"

    instructions = <<~PROMPT
      Rôle : Tu es un professeur expert en pédagogie. Ton but est de transformer un cours écrit en une fiche de révision parfaite, synthétique et facile à mémoriser.

      Tâche : À partir du document de cours fourni, rédige une fiche de révision structurée.
      Niveau de l'élève : #{context.level}.
      Matière : #{context.subject}.
      Titre du cours : '#{context.title}'.

      Structure obligatoire de la fiche :
      1. L'essentiel en 5 points : Un résumé ultra-court et percutant au début.
      2. Les concepts clés : Explication simple des grandes idées du cours.
      3. Attention au piège : Identifie 1 erreur fréquente que les élèves font souvent sur ce chapitre.

      Contraintes de formatage (OBLIGATOIRE POUR LE LOGICIEL) :
      - N'utilise JAMAIS de Markdown (interdiction stricte d'utiliser les symboles #, * ou **).
      - Pour mettre du texte en gras, utilise STRICTEMENT les balises HTML <b> et </b> (exemple : <b>mot important</b>).
      - Pour les titres de parties, écris-les simplement en MAJUSCULES et encadrés des balises <b>.
      - Pour faire une liste, utilise un simple tiret "-" en début de ligne.
      - Fais des phrases courtes et saute des lignes pour aérer la fiche.
    PROMPT

    attempts = 0
    texte_pour_la_fiche = nil
    begin
      Rails.logger.info("🚀 [Job] Appel API Gemini pour generate_summary - Context #{context.id} (tentative #{attempts + 1})")
      ruby_llm_chat = RubyLLM.chat(model: "gemini-3.1-flash-lite-preview").with_instructions(instructions)

      context.document.open do |temp_file|
        reponse_ia = ruby_llm_chat.ask("Analyse ce document et rédige une fiche de révision complète.", with: { pdf: temp_file.path })
        texte_pour_la_fiche = reponse_ia.content
      end

      Rails.logger.info("✅ [Job] Fin appel API Gemini pour generate_summary - Context #{context.id}")

    rescue RubyLLM::ServiceUnavailableError, RubyLLM::RateLimitError => e
      attempts += 1
      if attempts <= 2
        delay = attempts * 2
        Rails.logger.warn("⚠️ [Job] Tentative #{attempts} échouée (503), retry dans #{delay}s...")
        sleep(delay)
        retry
      else
        Rails.logger.error("[Job] Toutes les tentatives ont échoué pour generate_summary: #{e.message}")
        return
      end

    rescue RubyLLM::ContextLengthExceededError => e
      Rails.logger.error("[Job] Contexte trop long pour generate_summary: #{e.message}")
      return
    end

    # Générer le PDF avec police UTF-8
    Prawn::Fonts::AFM.hide_m17n_warning = true
    pdf = Prawn::Document.new

    # Utiliser une police TTF compatible UTF-8
    font_path = Rails.root.join("app", "assets", "fonts", "DejaVuSans.ttf")
    font_bold_path = Rails.root.join("app", "assets", "fonts", "DejaVuSans-Bold.ttf")
    if File.exist?(font_path)
      pdf.font_families.update("DejaVu" => {
        normal: font_path.to_s,
        bold: File.exist?(font_bold_path) ? font_bold_path.to_s : font_path.to_s
      })
      pdf.font "DejaVu"
    end

    texte_propre = texte_pour_la_fiche.to_s
      .gsub(/\*\*(.*?)\*\*/, '<b>\1</b>') # Transforme le gras Markdown (**) en balise HTML <b>
      .gsub(/^\s*\*\s*/, "- ")             # Remplace les puces Markdown (*) par de vrais tirets
      .gsub(/#+\s*/, "")                   # Supprime les symboles de titres Markdown (#)
      .gsub(/[\u2018\u2019]/, "'")         # Smart quotes -> apostrophe simple
      .gsub(/[\u201C\u201D]/, '"')         # Smart double quotes -> guillemets simples
      .gsub(/\u2026/, "...")               # Ellipsis -> trois points
      .gsub(/[\u2013\u2014]/, "-")         # Tirets spéciaux -> tiret simple
      .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    pdf.text "Fiche de révision : #{context.title}", size: 24, style: :bold
    pdf.move_down 20
    pdf.text texte_propre, size: 12, inline_format: true

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
