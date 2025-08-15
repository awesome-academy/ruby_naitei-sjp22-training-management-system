window.initCourseSubjectForm = function() {
  const container = document.getElementById('subject-list-container-in-course');
  const addBtn = document.getElementById('add-subject-row');
  const categorySelect = document.getElementById('category_id_for_subjects');

  if (!container || !categorySelect || !addBtn) return;

  const template = container.firstElementChild.cloneNode(true);

  container.innerHTML = '';

  let rowIndex = 0;

  const subjectSelects = () => Array.from(container.querySelectorAll('select'));

  function getExistingIds() {
    return subjectSelects()
      .map(s => parseInt(s.value, 10))
      .filter(v => !Number.isNaN(v));
  }

  function updateDisabledOptions() {
    const selected = getExistingIds().map(String);
    subjectSelects().forEach(sel => {
      Array.from(sel.options).forEach(opt => {
        opt.disabled = (opt.value && selected.includes(opt.value) && opt.value !== sel.value);
      });
    });
  }

  function addRowWithSubject(subjectId) {
    const row = template.cloneNode(true);

    row.querySelectorAll('input, select').forEach(el => {
      if (el.name) {
        el.name = el.name.replace(/\[\d+\]/, `[${rowIndex}]`);
        el.value = '';
      }
    });

    const subject = window.subjectData.find(s => s.id === subjectId);
    const positionInput = row.querySelector("input[name*='[position]']");

    if (subject && positionInput) {
      const categoryId = parseInt(categorySelect.value, 10);
      const category = subject.categories.find(c => c.id === categoryId);
      if (category) {
        positionInput.value = category.position;
      }
    }

    const sel = row.querySelector('select');
    if (sel) sel.value = String(subjectId);

    container.appendChild(row);
    updateDisabledOptions();

    rowIndex++;
  }

  addRowWithSubject('');

  addBtn.onclick = () => addRowWithSubject('');

  container.onclick = function(e) {
    if (e.target.classList.contains('remove-subject')) {
      if (container.children.length > 1) {
        e.target.closest('.subject-row').remove();
        updateDisabledOptions();
      }
    }
  };

  categorySelect.onchange = function() {
    const catId = parseInt(this.value, 10);
    container.innerHTML = '';
    rowIndex = 0;

    if (Number.isNaN(catId) || !window.subjectData) {
        addRowWithSubject('');
        return;
    }

    const subjectsInCat = window.subjectData.filter(s =>
      (s.categories || []).some(c => c.id === catId)
    );

    const existing = new Set();
    subjectsInCat.forEach(s => {
      if (!existing.has(s.id)) {
        addRowWithSubject(s.id);
        existing.add(s.id);
      }
    });

    updateDisabledOptions();
  };

  updateDisabledOptions();
};

document.addEventListener('DOMContentLoaded', window.initCourseSubjectForm);
