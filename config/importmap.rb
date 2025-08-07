# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "i18n-js", to: "https://ga.jspm.io/npm:i18n-js@4.5.1/dist/import/index.js"
pin "bignumber.js", to: "https://ga.jspm.io/npm:bignumber.js@9.3.1/bignumber.mjs"
pin "lodash/camelCase", to: "https://ga.jspm.io/npm:lodash@4.17.21/camelCase.js"
pin "lodash/get", to: "https://ga.jspm.io/npm:lodash@4.17.21/get.js"
pin "lodash/has", to: "https://ga.jspm.io/npm:lodash@4.17.21/has.js"
pin "lodash/merge", to: "https://ga.jspm.io/npm:lodash@4.17.21/merge.js"
pin "lodash/range", to: "https://ga.jspm.io/npm:lodash@4.17.21/range.js"
pin "lodash/repeat", to: "https://ga.jspm.io/npm:lodash@4.17.21/repeat.js"
pin "lodash/sortBy", to: "https://ga.jspm.io/npm:lodash@4.17.21/sortBy.js"
pin "lodash/uniq", to: "https://ga.jspm.io/npm:lodash@4.17.21/uniq.js"
pin "lodash/zipObject", to: "https://ga.jspm.io/npm:lodash@4.17.21/zipObject.js"
pin "make-plural", to: "https://ga.jspm.io/npm:make-plural@7.4.0/plurals.mjs"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/custom", under: "custom"
pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js"
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@3.4.1/dist/js/bootstrap.min.js"
