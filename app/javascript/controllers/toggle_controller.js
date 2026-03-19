import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hideable"]

  connect() {
    console.log("toggle controller connected")
  }

  call(event) {
    event.preventDefault()
    this.hideableTarget.classList.toggle("d-none")
  }
}
