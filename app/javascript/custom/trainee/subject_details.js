// Đóng modal xác nhận hoàn thành môn học
window.closeConfirmFinishModal = function() {
  var modal = document.getElementById('confirmFinishModal');
  if (modal) {
    modal.classList.remove('show');
    modal.style.display = 'none';
    modal.setAttribute('aria-hidden', 'true');
    modal.removeAttribute('aria-modal');
    var backdrop = document.querySelector('.modal-backdrop');
    if (backdrop) backdrop.remove();
  }
}
// Hiển thị modal xác nhận hoàn thành môn học
window.showConfirmFinishModal = function() {
  var modal = document.getElementById('confirmFinishModal');
  if (modal) {
    modal.classList.add('show');
    modal.style.display = 'block';
    modal.setAttribute('aria-modal', 'true');
    modal.removeAttribute('aria-hidden');
    // Tạo backdrop nếu chưa có
    if (!document.querySelector('.modal-backdrop')) {
      var backdrop = document.createElement('div');
      backdrop.className = 'modal-backdrop fade show';
      document.body.appendChild(backdrop);
    }
  }
}
document.addEventListener('turbo:load', function() {});

document.addEventListener('DOMContentLoaded', function() {});

// Hiển thị hoặc ẩn form tải lên tài liệu
window.toggleUploadForm = function(taskId) {
  var el = document.getElementById('uploadForm' + taskId);
  if (el.classList.contains('show')) {
    el.classList.remove('show');
  } else {
    el.classList.add('show');
  }
}

// Hiển thị hoặc ẩn phần xác nhận hoàn thành môn học
window.toggleFinishConfirm = function() {
      const section = document.getElementById('finishConfirmSection');
      if (section.classList.contains('show')) {
        section.classList.remove('show');
      } else {
        section.classList.add('show');
      }
    }

// Cập nhật giá trị của các trường ngày tháng trong form
window.updateFormDates = function () {
 // Lấy giá trị từ date inputs
  const startDate = document.getElementById('actual_start_date').value;
  const endDate = document.getElementById('actual_end_date').value;
  // Gán vào hidden fields của form
  document.getElementById('form_started_at').value = startDate || '<%= @user_subject.started_at || Date.current %>';
  document.getElementById('form_completed_at').value = endDate || '<%= @user_subject.completed_at || Date.current %>';
}
