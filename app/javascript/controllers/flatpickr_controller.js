import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { French } from "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  connect() {
    console.log("flatpickr controller connecté")

    flatpickr(this.element, {
      locale: French,
      altInput: true,
      altFormat: "j F Y",
      dateFormat: "Y-m-d",
    })
  }
}