import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const value = this.sourceTarget.value

    try {
      await navigator.clipboard.writeText(value)
      this.buttonTarget.textContent = "Lien copie"
    } catch (error) {
      this.sourceTarget.focus()
      this.sourceTarget.select()
      document.execCommand("copy")
      this.buttonTarget.textContent = "Lien copie"
    }

    window.setTimeout(() => {
      this.buttonTarget.textContent = "Copier le lien"
    }, 1800)
  }
}
