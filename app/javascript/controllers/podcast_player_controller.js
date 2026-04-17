import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio"]
  static values = { markUrl: String }

  connect() {
    const Plyr = window.Plyr
    if (!Plyr) return

    this.player = new Plyr(this.audioTarget, {
      controls: ["play", "progress", "current-time", "duration", "mute", "volume"]
    })
    this.audioTarget.addEventListener("play", () => this.markPlayed(), { once: true })
  }

  markPlayed() {
    fetch(this.markUrlValue, {
      method: "PATCH",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
  }

  disconnect() {
    this.player?.destroy()
  }
}
