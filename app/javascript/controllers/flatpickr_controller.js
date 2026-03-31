import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { French } from "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  connect() {
    flatpickr(this.element, {
      locale: French,
      altInput: true,
      altInputClass: "form-control context-form__input",
      altFormat: "j F Y",
      dateFormat: "Y-m-d",
    })
  }
}
