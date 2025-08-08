document.addEventListener('turbo:load', function() {
  document.querySelectorAll('.dropdown-toggle').forEach(function(btn) {
    btn.addEventListener('click', function(event) {
      event.preventDefault();
      let menu = btn.parentElement.querySelector('.dropdown-menu');
      if (menu) {
        menu.classList.toggle('active');
      }
    });
  });
});
