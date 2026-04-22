import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    const embed = this.element.querySelector("embed")
    if (embed) {
      embed.addEventListener("load", () => this.#update(), { once: true })
    } else {
      this.#update()
    }
  }

  #update() {
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
  }
}
