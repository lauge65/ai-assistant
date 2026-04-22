import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { markUrl: String, downloadUrl: String }

  download(event) {
    event.preventDefault()

    fetch(this.markUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))

    window.location.href = this.downloadUrlValue
  }
}
