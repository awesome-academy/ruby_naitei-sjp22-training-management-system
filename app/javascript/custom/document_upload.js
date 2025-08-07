import { I18n } from 'i18n-js';

const i18n = new I18n();

i18n.defaultLocale = document.documentElement.dataset.defaultLocale || 'en';
i18n.locale = document.documentElement.dataset.locale || 'en';

fetch('/locales.json')
  .then(response => response.json())
  .then(translations => {
    i18n.store(translations);
    window.I18n = i18n;
  });

document.addEventListener('turbo:load', function () {
    const localeFromPath = window.location.pathname.split('/')[1] || 'en';
    i18n.locale = localeFromPath;
    document.addEventListener('change', function (event) {
        // Select all elements with id starting with 'task_document_'
        let document_uploads = document.querySelectorAll('[id^="task_document_"]');
        document_uploads.forEach(document_upload => {
            if (!document_upload.files.length) return;
            const MAX_ALLOWED_SIZE_MB = parseFloat(document_upload.dataset.maxFileSizeMb);
            const ALLOWED_DOCUMENT_TYPES = document_upload.dataset.allowedDocumentTypes.split(",");
            let files = Array.from(document_upload.files);
            let exceeded = false;
            let invalidType = false;

            files.forEach(file => {
                const size_in_megabytes = file.size / 1024 / 1024;
                if (size_in_megabytes > MAX_ALLOWED_SIZE_MB) {
                    exceeded = true;
                }
                if (!ALLOWED_DOCUMENT_TYPES.includes(file.type)) {
                    invalidType = true;
                }
            });

            if (exceeded) {
                alert(i18n.t('activerecord.errors.models.user_task.attributes.documents.document_size_exceeded', { size: MAX_ALLOWED_SIZE_MB }));
                document_upload.value = '';
            } else if (invalidType) {
                alert(i18n.t('activerecord.errors.models.user_task.attributes.documents.invalid_document_type', { types: ALLOWED_DOCUMENT_TYPES.join(', ') }));
                document_upload.value = '';
            }
        });
    });
});
