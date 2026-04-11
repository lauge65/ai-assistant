import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 700 }
  }

  scheduleReload() {
    window.setTimeout(() => {
      window.location.reload()
    }, this.delayValue)
  }
}
