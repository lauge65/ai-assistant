import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    alreadyRead: Boolean
  }

  connect() {
    if (this.alreadyReadValue) return

    this._marked = false
    this._handleScroll = this.#checkScroll.bind(this)
    window.addEventListener("scroll", this._handleScroll, { passive: true })
    this.#checkScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this._handleScroll)
  }

  #checkScroll() {
    if (this._marked) return

    const scrolled = window.scrollY + window.innerHeight
    const total = document.documentElement.scrollHeight

    if (scrolled / total >= 0.9) {
      this._marked = true
      window.removeEventListener("scroll", this._handleScroll)

      fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        }
      })
    }
  }
}
