window.initSubjectForm = function () {
  const container = document.getElementById('subject-list-container');
  const addBtn = document.getElementById('add-subject-row');
  
  if (!container) return;

  function getSubjectSelects(scope = container) {
    return Array.from(scope.querySelectorAll('.subject-row select')).filter(Boolean);
  }

  function updateDisabledOptions() {
    const selects = getSubjectSelects();
    const chosen = selects.map(s => s.value).filter(v => v);
    selects.forEach(sel => {
      Array.from(sel.options).forEach(opt => {
        if (!opt.value) return;
        opt.disabled = chosen.includes(opt.value) && opt.value !== sel.value;
      });
    });
  }

  function computeNextIndex() {
    let maxIdx = -1;
    const inputs = container.querySelectorAll("input[name*='[subject_categories_attributes]'], select[name*='[subject_categories_attributes]']");
    inputs.forEach(el => {
      const m = el.name.match(/\[subject_categories_attributes\]\[([^\]]+)\]/);
      if (m && /^\d+$/.test(m[1])) {
        const n = parseInt(m[1], 10);
        if (!Number.isNaN(n)) maxIdx = Math.max(maxIdx, n);
      }
    });
    return maxIdx + 1;
  }

  function reindexRow(row, newIndex) {
    row.querySelectorAll('input, select, textarea').forEach(el => {
      if (!el.name) return;
      el.name = el.name.replace(/(\[subject_categories_attributes\])\[[^\]]+\]/, `$1[${newIndex}]`);
    });
  }

  function resetRowValues(row) {
    row.querySelectorAll('input, select, textarea').forEach(el => {
      const type = (el.getAttribute('type') || '').toLowerCase();
      if (el.tagName === 'SELECT') el.selectedIndex = 0;
      else if (type === 'checkbox' || type === 'radio') el.checked = false;
      else if (type !== 'hidden') el.value = '';
      if (/\[_destroy\]$/.test(el.name)) el.value = '0';
    });
  }

  function bindRowEvents(row) {
    const sel = row.querySelector('select');
    if (sel) sel.addEventListener('change', updateDisabledOptions);

    const removeBtn = row.querySelector('.remove-subject');
    if (removeBtn) {
      removeBtn.addEventListener('click', function (e) {
        e.preventDefault();
        const destroyInput = row.querySelector("input[name$='[_destroy]']");
        const idInput = row.querySelector("input[name$='[id]']");

        if (idInput && idInput.value) {
          // persisted row: mark _destroy
          if (destroyInput) destroyInput.value = '1';
          row.style.display = 'none';
        } else {
          // new row: remove trực tiếp
          row.remove();
        }
        updateDisabledOptions();
      });
    }
  }

  // function getTemplateRow() {
  //   const firstRow = container.querySelector('.subject-row');
  //   if (!firstRow) return null;
  //   return firstRow.cloneNode(true);
  // }

  function addRow(prefill = null) {
    const template = document.querySelector('#subject-row-template .subject-row').cloneNode(true);
    if (!template) return;
    resetRowValues(template);
    // Xóa lỗi Rails nếu có
    const removeBtn = template.querySelector('.remove-subject');
    if (removeBtn) removeBtn.textContent = removeBtn.dataset.deleteText;


    const nextIndex = computeNextIndex();
    reindexRow(template, nextIndex);
    resetRowValues(template);


    bindRowEvents(template);
    container.appendChild(template);
    updateDisabledOptions();
  }

  // Bind row hiện có
  container.querySelectorAll('.subject-row').forEach(row => bindRowEvents(row));
  updateDisabledOptions();

  if (addBtn) {
    addBtn.addEventListener('click', e => {
      e.preventDefault();
      addRow();
    });
  }

  // Nếu form trống, thêm 1 row mới
  if (container.querySelectorAll('.subject-row').length === 0) {
    addRow();
  }
};

document.addEventListener('DOMContentLoaded', window.initSubjectForm);
