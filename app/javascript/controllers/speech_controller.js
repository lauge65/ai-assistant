import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  connect() {
    this.isRecording = false
    this.defaultButtonHTML = '<i class="fa-solid fa-microphone"></i>'
    this.recordingButtonHTML = 'En cours...'

  }

  toggle() {
    if (this.isRecording) {
      this.stop()
    } else {
      this.start()
    }
  }

  start() {
    const SpeechRecognition =
      window.SpeechRecognition || window.webkitSpeechRecognition

    if (!SpeechRecognition) {
      alert("La reconnaissance vocale n'est pas disponible sur ce navigateur.")
      return
    }

    this.recognition = new SpeechRecognition()
    this.recognition.lang = "fr-FR"
    this.recognition.interimResults = false
    this.recognition.maxAlternatives = 1

    this.isRecording = true
    this.buttonTarget.textContent = this.recordingButtonHTML

    this.recognition.onresult = (event) => {
      const text = event.results[0][0].transcript
      this.inputTarget.value = text
    }

    this.recognition.onend = () => {
      this.reset()
    }

    this.recognition.onerror = () => {
      this.reset()
      alert("Erreur lors de l'utilisation du micro.")
    }

    this.recognition.start()
  }

  stop() {
    if (this.recognition) {
      this.recognition.stop()
    }
    this.reset()
  }

  reset() {
    this.isRecording = false
    this.buttonTarget.innerHTML = this.defaultButtonHTML
  }
}
