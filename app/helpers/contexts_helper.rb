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
end
