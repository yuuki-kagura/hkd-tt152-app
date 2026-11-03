-- =============================================
-- 20261103002: Lý do hiển thị của hóa đơn thay thế / điều chỉnh đã cache
--
-- 20261103001 chỉ vá nhóm "đã bị thay thế/điều chỉnh/hủy". Những dòng tthai=2/3
-- vẫn mang câu lý do cũ "không tự tạo phiếu nhập", trong khi từ bản này chúng có
-- nút Nhập kho — đúng chỗ người dùng thắc mắc "cần xử lý mà không biết xử lý gì".
-- Ngày đã có cache thì quét lại không tải lại nên text cũ ở vĩnh viễn.
-- Tính lại theo tthai chứ không thế chuỗi: bản cũ từng ghi nhiều kiểu wording.
-- =============================================

UPDATE hddt_purchase_invoice
   SET skip_reason = CASE tthai
           WHEN 2 THEN 'Hóa đơn thay thế — bấm Nhập kho'
           WHEN 3 THEN 'Hóa đơn điều chỉnh — bấm Nhập kho'
       END
 WHERE tthai IN (2, 3)
   AND status IN ('pending', 'manual');
