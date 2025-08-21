console.log(document.querySelectorAll('.clickable-task'));
document.addEventListener('turbo:load', function () {
  // Toggle task submissions
  document.querySelectorAll('.clickable-task').forEach(function (taskElement) {
    taskElement.addEventListener('click', function () {
      const taskId = this.dataset.taskId;
      const submissionsDiv = document.getElementById(
        'taskSubmissions' + taskId
      );
      const taskItem = document.querySelector(
        '[data-task-id="' + taskId + '"]'
      );

      if (submissionsDiv) {
        if (submissionsDiv.classList.contains('show')) {
          submissionsDiv.classList.remove('show');
          taskItem.classList.remove('expanded');
        } else {
          // Close other open submissions
          document
            .querySelectorAll('.task-submissions.show')
            .forEach(function (openSubmission) {
              openSubmission.classList.remove('show');
            });
          document
            .querySelectorAll('.task-item.expanded')
            .forEach(function (expandedTask) {
              expandedTask.classList.remove('expanded');
            });

          // Open current submission
          submissionsDiv.classList.add('show');
          taskItem.classList.add('expanded');
        }
      }
    });
  });
});
