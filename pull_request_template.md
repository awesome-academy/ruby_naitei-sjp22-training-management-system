## Checklist tự review pull trước khi ready nhờ trainer review
- [ ] Kiểm tra mỗi pull request 1 commit, nếu nhiều commit thì hãy gộp commit thành 1 rồi đẩy lại lên git
- [ ] Trong các file của rails (đuôi .erb, .rb, .yml): sử dụng nháy " thay vì nháy '
- [ ] Trong file javascript: sử dụng nháy ' thay vì "
- [ ] Sử dụng thụt lề 2 space (setting lại vscode /sublime text nếu chưa cài đặt)
- [ ] Cuối mỗi file kiểm tra có end line (khi đẩy lên git xem file change k bị lỗi tròn đỏ ở cuối file)
- [ ] Mỗi dòng nếu quá dài, cần xuống dòng (maximum: 80 kí tự mỗi dòng)
- [ ] Xóa các file được tự động sinh ra khi dùng các câu lệnh rails generate ... tạo ra nhưng k dùng đến, không có dòng code nào được viết trong đó (hay gặp nhất là các file helper)
- [ ] Khi tạo mảng, nên tích cực sử dụng %w( ), %i() . Thay vì STATES = ['draft', 'open', 'closed'] có thể dùng STATES = %w(draft open closed)
- [ ] Xem các lỗi hay gặp khi triển khai Rails tutorial tại https://docs.google.com/document/d/104Csp4-vamVos5DEbi372nLBEfmqhj7h1ENYO8ebjCo/edit
- [ ] Tham khảo coding convention https://github.com/framgia/coding-standards/blob/master/vn/README.md

## Related Tickets
- ticket redmine

## WHAT (optional)
- Change number items `completed/total` in admin page.

## HOW
- I edit js file, inject not_vary_normal items in calculate function.

## WHY (optional)
- Because in previous version - number just depends on `normal` items. But in new version, we have `state` and `confirm_state` depends on both `normal` + `not_normal` items.

## Evidence (Screenshot or Video)


## Notes (Kiến thức tìm hiểu thêm)
