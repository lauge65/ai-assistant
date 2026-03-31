import { Controller } from "@hotwired/stimulus"

// Ce contrôleur observe les mutations du DOM et scrolle automatiquement vers le bas
// quand de nouveaux messages sont ajoutés ou mis à jour (streaming)
export default class extends Controller {
  connect() {
    this.scrollToBottom()

    // Observer les changements dans le conteneur des messages
    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
    })

    this.observer.observe(this.element, {
      childList: true,      // Observer l'ajout/suppression d'enfants
      subtree: true,        // Observer aussi les descendants
      characterData: true   // Observer les changements de texte (pour le streaming)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
