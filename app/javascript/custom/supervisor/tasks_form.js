document.addEventListener('turbo:load', function() {
  const container = document.getElementById('tasks-form-container')
  if (!container) return

  const addBtn = document.getElementById('add-task-btn')
  const newTasksContainer = document.getElementById('new-tasks-container')
  const template = document.getElementById('task-template')

  if (addBtn && template && newTasksContainer) {
    addBtn.addEventListener('click', function() {
      const newIndex = new Date().getTime()
      const templateContent = template.innerHTML.replace(/NEW_INDEX/g, newIndex)

      newTasksContainer.insertAdjacentHTML('beforeend', templateContent)
      newTasksContainer.lastElementChild.scrollIntoView({ behavior: 'smooth' })
    })
  }

  container.addEventListener('click', function(event) {
    if (event.target.classList.contains('remove-new-task-btn')) {
      event.target.closest('.task-item').remove()
    }
  })

  container.addEventListener('click', function(event) {
    if (event.target.classList.contains('task-delete-btn')) {
      const taskItem = event.target.closest('.task-item')
      const destroyInput = taskItem.querySelector('.task-destroy-hidden-field')
      const nameInput = taskItem.querySelector('input[type="text"]')

      if (destroyInput.value === 'false') {
        destroyInput.value = 'true'
        nameInput.style.textDecoration = 'line-through'
      } else {
      destroyInput.value = 'false'
      nameInput.style.textDecoration = 'none'
      }
    }
  })
})
