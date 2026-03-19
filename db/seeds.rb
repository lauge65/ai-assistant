puts "Cleaning database..."

Message.destroy_all
Chat.destroy_all
Context.destroy_all
User.destroy_all

puts "Creating demo user..."

user = User.create!(
  email: "demo@easylearn.com",
  password: "123456"
)

puts "Creating contexts..."


systeme_solaire = Context.new(
  title: "Le système solaire",
  subject: "Physique-Chimie",
  level: "6ème",
  date: Date.new(2026, 3, 1),
  user: user
)

file = File.open(Rails.root.join("db/seeds/systeme_solaire.pdf"))
systeme_solaire.document.attach(
  io: file,
  filename: "systeme_solaire.pdf",
  content_type: "application/pdf"
)

systeme_solaire.save!

systeme_solaire_chat = Chat.create!(context: systeme_solaire)

Message.create!(
  content: "Bonjour, peux-tu me rappeler l'ordre des planètes du système solaire ?",
  role: "user",
  chat: systeme_solaire_chat
)

Message.create!(
  content: "Bien sûr. En partant du Soleil : Mercure, Vénus, la Terre, Mars, Jupiter, Saturne, Uranus et Neptune.",
  role: "assistant",
  chat: systeme_solaire_chat
)


melanges = Context.new(
  title: "Mélanges et corps purs",
  subject: "Physique-Chimie",
  level: "2nde",
  date: Date.new(2026, 3, 5),
  user: user
)

file = File.open(Rails.root.join("db/seeds/melanges_et_corps_purs.pdf"))
melanges.document.attach(
  io: file,
  filename: "melanges_et_corps_purs.pdf",
  content_type: "application/pdf"
)

melanges.save!

melanges_chat = Chat.create!(context: melanges)

Message.create!(
  content: "Quelle est la différence entre un corps pur et un mélange ?",
  role: "user",
  chat: melanges_chat
)

Message.create!(
  content: "Un corps pur est constitué d’une seule espèce chimique, alors qu’un mélange contient plusieurs espèces chimiques.",
  role: "assistant",
  chat: melanges_chat
)


ue = Context.new(
  title: "L'Union européenne",
  subject: "Géographie",
  level: "3ème",
  date: Date.new(2026, 3, 10),
  user: user
)

file = File.open(Rails.root.join("db/seeds/ue_geographie.pdf"))
ue.document.attach(
  io: file,
  filename: "ue_geographie.pdf",
  content_type: "application/pdf"
)

ue.save!

ue_chat = Chat.create!(context: ue)

Message.create!(
  content: "Quels sont les principaux pays membres de l'Union européenne ?",
  role: "user",
  chat: ue_chat
)

Message.create!(
  content: "L’Union européenne compte plusieurs États membres, dont la France, l’Allemagne, l’Italie, l’Espagne, la Belgique et les Pays-Bas.",
  role: "assistant",
  chat: ue_chat
)

Message.create!(
  content: "À quoi sert la carte dans ce cours ?",
  role: "user",
  chat: ue_chat
)

Message.create!(
  content: "La carte permet de repérer les États membres, leurs frontières, leur position en Europe et les grands espaces de coopération.",
  role: "assistant",
  chat: ue_chat
)

puts "Finished!"
puts "#{User.count} user created"
puts "#{Context.count} contexts created"
puts "#{Chat.count} chats created"
puts "#{Message.count} messages created"
