# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Contrôleurs Stimulus - pins explicites pour la production
pin "controllers/application", to: "controllers/application.js"
pin "controllers/autoscroll_controller", to: "controllers/autoscroll_controller.js"
pin "controllers/chat_form_controller", to: "controllers/chat_form_controller.js"
pin "controllers/clipboard_controller", to: "controllers/clipboard_controller.js"
pin "controllers/flatpickr_controller", to: "controllers/flatpickr_controller.js"
pin "controllers/hello_controller", to: "controllers/hello_controller.js"
pin "controllers/toggle_controller", to: "controllers/toggle_controller.js"
pin "controllers", to: "controllers/index.js"

pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "flatpickr" # @4.6.13
pin "flatpickr/dist/l10n/fr.js", to: "flatpickr--dist--l10n--fr.js.js" # @4.6.13
