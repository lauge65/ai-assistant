import { Controller } from "@hotwired/stimulus"

// Ce contrôleur gère le formulaire de chat
// - Désactive le bouton pendant l'envoi
// - Réinitialise le formulaire après l'envoi
export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.element.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSubmitStart() {
    // Désactiver le bouton et afficher un état de chargement
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      this.originalText = this.submitTarget.textContent
      this.submitTarget.textContent = "Envoi..."
    }
  }

  handleSubmitEnd() {
    // Réactiver le bouton et vider le champ
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = this.originalText || "Envoyer"
    }

    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }
  }
}
