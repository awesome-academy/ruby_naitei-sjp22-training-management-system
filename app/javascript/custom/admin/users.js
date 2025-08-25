document.addEventListener('turbo:load', function () {
  // Track if document listeners have been added to avoid duplicates
  let dropdownDocumentListenerAdded = false;

  // Initialize dropdowns first
  initializeDropdowns();

  // Initialize submenu hover
  initializeSubmenu();

  // Initialize modal triggers
  initializeModalTriggers();

  function initializeModalTriggers() {
    // Handle modal trigger links
    const modalTriggers = document.querySelectorAll(
      '[data-toggle="modal"], [data-bs-toggle="modal"]'
    );

    if (!modalTriggers || modalTriggers.length === 0) {
      return;
    }

    modalTriggers.forEach(trigger => {
      // Check if element exists and hasn't already been initialized
      if (!trigger || trigger.hasAttribute('data-modal-initialized')) {
        return;
      }

      trigger.addEventListener('click', function (e) {
        // Close all dropdowns immediately when modal trigger is clicked
        closeAllDropdowns();
        // Small delay to ensure dropdowns are closed
        setTimeout(() => {
          closeAllDropdowns();
        }, 10);
      });

      // Mark as initialized to prevent duplicate event listeners
      trigger.setAttribute('data-modal-initialized', 'true');
    });
  }

  function closeAllDropdowns() {
    // Close all dropdown menus
    document.querySelectorAll('.dropdown').forEach(dropdown => {
      dropdown.classList.remove('open');
      const row = dropdown.closest('.supervisor-row');
      if (row) row.classList.remove('dropdown-open');
    });

    // Hide all dropdown menus
    document.querySelectorAll('.dropdown-menu').forEach(menu => {
      menu.style.display = 'none';
    });

    // Remove all submenu displays
    document
      .querySelectorAll('.dropdown-submenu .dropdown-menu')
      .forEach(submenu => {
        submenu.style.display = 'none';
      });
  }

  function initializeSubmenu() {
    const submenuItems = document.querySelectorAll('.dropdown-submenu');

    if (!submenuItems || submenuItems.length === 0) {
      return;
    }

    submenuItems.forEach(function (submenu) {
      // Check if submenu exists and hasn't been initialized
      if (!submenu || submenu.hasAttribute('data-submenu-initialized')) {
        return;
      }

      const submenuToggle = submenu.querySelector('.dropdown-item');
      const submenuDropdown = submenu.querySelector('.dropdown-menu');

      // Validate required elements exist
      if (!submenuToggle || !submenuDropdown) {
        return;
      }

      submenuToggle.addEventListener('mouseenter', function () {
        if (submenuDropdown && typeof submenuDropdown.style !== 'undefined') {
          submenuDropdown.style.display = 'block';
        }
      });

      submenu.addEventListener('mouseleave', function () {
        if (submenuDropdown && typeof submenuDropdown.style !== 'undefined') {
          submenuDropdown.style.display = 'none';
        }
      });

      // Mark as initialized
      submenu.setAttribute('data-submenu-initialized', 'true');
    });
  }

  function initializeDropdowns() {
    const dropdownToggles = document.querySelectorAll('.dropdown-toggle');

    if (!dropdownToggles || dropdownToggles.length === 0) {
      return;
    }

    dropdownToggles.forEach(toggle => {
      // Check if element exists and hasn't been initialized
      if (!toggle || toggle.hasAttribute('data-dropdown-initialized')) {
        return;
      }

      toggle.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();

        // Close all other dropdowns and remove z-index elevation from rows
        document.querySelectorAll('.dropdown').forEach(dropdown => {
          if (dropdown !== this.closest('.dropdown')) {
            dropdown.classList.remove('open');
            const row = dropdown.closest('.supervisor-row');
            if (row) row.classList.remove('dropdown-open');
          }
        });

        // Toggle current dropdown
        const dropdown = this.closest('.dropdown');
        const row = this.closest('.supervisor-row');

        if (dropdown) {
          const isOpening = !dropdown.classList.contains('open');
          dropdown.classList.toggle('open');

          // Add or remove z-index elevation to the row
          if (row) {
            if (isOpening) {
              row.classList.add('dropdown-open');
            } else {
              row.classList.remove('dropdown-open');
            }
          }
        }
      });

      // Mark as initialized
      toggle.setAttribute('data-dropdown-initialized', 'true');
    });

    // Check if document click listener hasn't been added yet
    if (!dropdownDocumentListenerAdded) {
      // Close dropdown when clicking outside
      document.addEventListener('click', function (e) {
        if (!e.target.closest('.dropdown')) {
          document.querySelectorAll('.dropdown').forEach(dropdown => {
            dropdown.classList.remove('open');
            const row = dropdown.closest('.supervisor-row');
            if (row) row.classList.remove('dropdown-open');
          });
        }
      });

      // Mark document listener as added
      dropdownDocumentListenerAdded = true;
    }
  }

  const selectAll = document.getElementById('select-all');
  const checkboxes = document.querySelectorAll('.supervisor-checkbox');
  const bulkActions = document.querySelector('.bulk-actions');
  const bulkDeleteBtn = document.getElementById('bulk-delete-btn');
  const bulkDeactivateBtn = document.getElementById(
    'bulk-deactivate-btn-admin-page'
  );
  const selectedCount = document.querySelector('.selected-count');
  const clearSearchBtn = document.querySelector('.clear-search');

  // Clear search functionality
  if (clearSearchBtn) {
    // Check if not already initialized
    if (!clearSearchBtn.hasAttribute('data-clear-initialized')) {
      clearSearchBtn.addEventListener('click', function () {
        const searchInput = document.querySelector('.search-input');
        if (searchInput && searchInput.form) {
          searchInput.value = '';
          searchInput.form.submit();
        }
      });
      clearSearchBtn.setAttribute('data-clear-initialized', 'true');
    }
  }

  // Select/Deselect all functionality
  if (selectAll && !selectAll.hasAttribute('data-select-initialized')) {
    selectAll.addEventListener('change', function () {
      if (checkboxes && checkboxes.length > 0) {
        checkboxes.forEach(checkbox => {
          if (checkbox) {
            checkbox.checked = this.checked;
          }
        });
        updateBulkActions();
      }
    });
    selectAll.setAttribute('data-select-initialized', 'true');
  }

  // Individual checkbox change
  if (checkboxes && checkboxes.length > 0) {
    checkboxes.forEach(checkbox => {
      // Check if checkbox exists and hasn't been initialized
      if (!checkbox || checkbox.hasAttribute('data-checkbox-initialized')) {
        return;
      }

      checkbox.addEventListener('change', function () {
        const checkedBoxes = document.querySelectorAll(
          '.supervisor-checkbox:checked'
        );
        const checkedCount = checkedBoxes ? checkedBoxes.length : 0;

        if (selectAll) {
          selectAll.checked = checkedCount === checkboxes.length;
          selectAll.indeterminate =
            checkedCount > 0 && checkedCount < checkboxes.length;
        }
        updateBulkActions();
      });

      checkbox.setAttribute('data-checkbox-initialized', 'true');
    });
  }

  function updateBulkActions() {
    const checkedBoxes = document.querySelectorAll(
      '.supervisor-checkbox:checked'
    );
    const checkedCount = checkedBoxes ? checkedBoxes.length : 0;
    const anyChecked = checkedCount > 0;

    if (bulkActions) {
      bulkActions.style.display = anyChecked ? 'block' : 'none';
    }

    if (selectedCount) {
      selectedCount.textContent = checkedCount;
    }
  }

  // Bulk deactivate functionality
  if (
    bulkDeactivateBtn &&
    !bulkDeactivateBtn.hasAttribute('data-bulk-initialized')
  ) {
    bulkDeactivateBtn.addEventListener('click', function () {
      const selectedIds = getSelectedIds();
      if (!selectedIds || selectedIds.length === 0) {
        return;
      }

      performBulkAction('/admin/users/bulk_deactivate', selectedIds, 'PATCH');
    });
    bulkDeactivateBtn.setAttribute('data-bulk-initialized', 'true');
  }

  function getSelectedIds() {
    const checkedBoxes = document.querySelectorAll(
      '.supervisor-checkbox:checked'
    );
    return Array.from(checkedBoxes).map(checkbox => checkbox.value);
  }

  function performBulkAction(url, ids, method) {
    // Validate parameters
    if (!url || !ids || !Array.isArray(ids) || ids.length === 0 || !method) {
      console.error('performBulkAction: Invalid parameters');
      return;
    }

    // Check for CSRF token
    const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');
    if (!csrfTokenElement) {
      console.error('performBulkAction: CSRF token not found');
      return;
    }

    const form = document.createElement('form');
    form.method = 'POST';
    form.action = url;

    // Add CSRF token
    const csrfToken = csrfTokenElement.getAttribute('content');
    if (csrfToken) {
      const csrfInput = document.createElement('input');
      csrfInput.type = 'hidden';
      csrfInput.name = 'authenticity_token';
      csrfInput.value = csrfToken;
      form.appendChild(csrfInput);
    }

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
      if (id) {
        const idInput = document.createElement('input');
        idInput.type = 'hidden';
        idInput.name = 'supervisor_ids[]';
        idInput.value = id;
        form.appendChild(idInput);
      }
    });

    if (document.body) {
      document.body.appendChild(form);
      form.submit();
    }
  }

  // Edit Profile Modal functionality
  const editProfileModal = document.getElementById('editProfileModal');
  const editProfileForm = document.getElementById('editProfileForm');

  if (editProfileModal && editProfileForm) {
    // Multiple event listeners to ensure dropdowns close
    // Bootstrap 4 syntax (jQuery)
    if (
      window.$ &&
      window.$.fn.modal &&
      !editProfileModal.hasAttribute('data-jquery-modal-initialized')
    ) {
      $(editProfileModal).on('show.bs.modal', function () {
        closeAllDropdowns();
        clearFormErrors();
      });
      editProfileModal.setAttribute('data-jquery-modal-initialized', 'true');
    }

    // Bootstrap 5 syntax (vanilla JS)
    if (!editProfileModal.hasAttribute('data-vanilla-modal-initialized')) {
      editProfileModal.addEventListener('show.bs.modal', function () {
        closeAllDropdowns();
        clearFormErrors();
      });
      editProfileModal.setAttribute('data-vanilla-modal-initialized', 'true');
    }

    // Backup - close dropdowns when modal is fully shown
    if (!editProfileModal.hasAttribute('data-modal-shown-initialized')) {
      editProfileModal.addEventListener('shown.bs.modal', function () {
        closeAllDropdowns();
      });
      editProfileModal.setAttribute('data-modal-shown-initialized', 'true');
    }

    // Handle form submission (regular form submission, not AJAX)
    if (!editProfileForm.hasAttribute('data-form-initialized')) {
      editProfileForm.addEventListener('submit', function (event) {
        // Let the form submit normally to the server
        // No need to prevent default - we want regular form submission
      });
      editProfileForm.setAttribute('data-form-initialized', 'true');
    }

    function clearFormErrors() {
      const invalidFields = document.querySelectorAll('.is-invalid');
      const feedbackElements = document.querySelectorAll('.invalid-feedback');

      if (invalidFields && invalidFields.length > 0) {
        invalidFields.forEach(field => {
          if (field && field.classList) {
            field.classList.remove('is-invalid');
          }
        });
      }

      if (feedbackElements && feedbackElements.length > 0) {
        feedbackElements.forEach(feedback => {
          if (feedback) {
            feedback.textContent = '';
          }
        });
      }
    }
  }
});
