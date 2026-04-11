module ContextsHelper
  def subject_theme(subject)
    normalized = I18n.transliterate(subject.to_s).downcase.strip

    case normalized
    when /math|geometr|algebre|arith/
      "theme-maths"
    when /histoire|geo|geographie|guerre/
      "theme-histoire"
    when /francais|litterature|grammaire|redaction/
      "theme-francais"
    when /anglais|espagnol|allemand|italien|langue/
      "theme-langues"
    when /svt|science|physique|chimie|biologie/
      "theme-sciences"
    else
      "theme-default"
    end
  end

  def progress_ring_style(context)
    percentage = context.progress_percentage
    circumference = 2 * Math::PI * 52
    progress = circumference - (circumference * percentage / 100.0)
    accent = context_progress_color(context.subject)

    "--progress-offset: #{progress.round(2)}; --progress-accent: #{accent}; --progress-accent-soft: #{hex_to_rgba(accent, 0.16)};"
  end

  def context_progress_color(subject)
    normalized = I18n.transliterate(subject.to_s).downcase.strip

    case normalized
    when /math|geometr|algebre|arith/
      "#2563eb"
    when /histoire|geo|geographie|guerre/
      "#b45309"
    when /francais|litterature|grammaire|redaction/
      "#be185d"
    when /anglais|espagnol|allemand|italien|langue/
      "#0f766e"
    when /svt|science|physique|chimie|biologie/
      "#059669"
    else
      "#4f46e5"
    end
  end

  private

  def hex_to_rgba(hex, alpha)
    sanitized = hex.delete("#")
    red = sanitized[0..1].to_i(16)
    green = sanitized[2..3].to_i(16)
    blue = sanitized[4..5].to_i(16)

    "rgba(#{red}, #{green}, #{blue}, #{alpha})"
  end
end
