document.addEventListener('turbo:load', function() {
  const selectAll = document.getElementById('select-all');
  const checkboxes = document.querySelectorAll('.trainee-checkbox');
  const bulkActions = document.querySelector('.bulk-actions');
  const bulkDeleteBtn = document.getElementById('bulk-delete-btn');
  const bulkDeactivateBtn = document.getElementById('bulk-deactivate-btn');
  const selectedCount = document.querySelector('.selected-count');
  const clearSearchBtn = document.querySelector('.clear-search');

  // Clear search functionality
  if (clearSearchBtn) {
    clearSearchBtn.addEventListener('click', function() {
      const searchInput = document.querySelector('.search-input');
      searchInput.value = '';
      searchInput.form.submit();
    });
  }

  // Select/Deselect all functionality
  selectAll.addEventListener('change', function() {
    checkboxes.forEach(checkbox => {
      checkbox.checked = this.checked;
    });
    updateBulkActions();
  });

  // Individual checkbox change
  checkboxes.forEach(checkbox => {
    checkbox.addEventListener('change', function() {
      const checkedCount = document.querySelectorAll('.trainee-checkbox:checked').length;
      selectAll.checked = checkedCount === checkboxes.length;
      selectAll.indeterminate = checkedCount > 0 && checkedCount < checkboxes.length;
      updateBulkActions();
    });
  });

  function updateBulkActions() {
    const checkedCount = document.querySelectorAll('.trainee-checkbox:checked').length;
    const anyChecked = checkedCount > 0;
    
    bulkActions.style.display = anyChecked ? 'block' : 'none';
    if (selectedCount) {
      selectedCount.textContent = checkedCount;
    }
  }

  // Bulk deactivate functionality
  bulkDeactivateBtn.addEventListener('click', function() {
    const selectedIds = getSelectedIds();
    if (selectedIds.length === 0) {
      alert('<%= t("trainee_manager.no_selection") %>');
      return;
    }

    if (confirm('<%= t("trainee_manager.bulk_deactivate_confirm") %>')) {
      performBulkAction('/trainee_manager/bulk_deactivate', selectedIds, 'PATCH');
    }
  });

  function getSelectedIds() {
    const checkedBoxes = document.querySelectorAll('.trainee-checkbox:checked');
    return Array.from(checkedBoxes).map(checkbox => checkbox.value);
  }

  function performBulkAction(url, ids, method) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = url;

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    const csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = 'authenticity_token';
    csrfInput.value = csrfToken;
    form.appendChild(csrfInput);

    // Add method override for PATCH/DELETE
    if (method !== 'POST') {
      const methodInput = document.createElement('input');
      methodInput.type = 'hidden';
      methodInput.name = '_method';
      methodInput.value = method;
      form.appendChild(methodInput);
    }

    // Add selected IDs
    ids.forEach(id => {
      const idInput = document.createElement('input');
      idInput.type = 'hidden';
      idInput.name = 'trainee_ids[]';
      idInput.value = id;
      form.appendChild(idInput);    
    });

    document.body.appendChild(form);
    form.submit();
  }
});
