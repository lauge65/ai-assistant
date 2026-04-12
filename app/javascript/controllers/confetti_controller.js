import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    active: Boolean
  }

  connect() {
    if (!this.activeValue) return

    this.launch()
  }

  launch() {
    const colors = ["#e60f05", "#ff8a1f", "#2563eb", "#059669", "#be185d", "#facc15"]
    const pieceCount = 80

    for (let index = 0; index < pieceCount; index += 1) {
      const piece = document.createElement("span")
      const horizontalOffset = Math.random() * 100
      const drift = (Math.random() - 0.5) * 220
      const rotation = Math.random() * 540
      const duration = 2200 + Math.random() * 1400
      const delay = Math.random() * 180
      const size = 8 + Math.random() * 10
      const color = colors[index % colors.length]

      piece.className = "confetti-piece"
      piece.style.left = `${horizontalOffset}%`
      piece.style.top = "-8%"
      piece.style.width = `${size}px`
      piece.style.height = `${size * 1.6}px`
      piece.style.background = color
      piece.style.setProperty("--confetti-drift", `${drift}px`)
      piece.style.setProperty("--confetti-rotate", `${rotation}deg`)
      piece.style.animationDuration = `${duration}ms`
      piece.style.animationDelay = `${delay}ms`

      this.element.appendChild(piece)

      window.setTimeout(() => piece.remove(), duration + delay + 200)
    }

    window.setTimeout(() => {
      this.element.innerHTML = ""
    }, 4200)
  }
}
