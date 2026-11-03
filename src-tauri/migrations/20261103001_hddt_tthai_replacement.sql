-- =============================================
-- 20261103001: Trạng thái hóa đơn (tthai) + con trỏ hóa đơn gốc
--
-- 1) tthai trước đây chỉ nằm trong raw_json, lý do bỏ qua chỉ sót lại trong
--    chuỗi skip_reason → không phân biệt được "hóa đơn thay thế" (còn phải
--    nhập) với "hóa đơn đã bị thay thế" (không bao giờ nhập). Nâng lên cột để
--    tách hai nhóm và tra được hóa đơn gốc.
-- 2) khhdgoc/shdgoc/tdlhdgoc: cổng trỏ về hóa đơn gốc bằng 3 trường này. Có
--    nó mới biết phiếu nhập của bản gốc đã tạo chưa mà đảo ngược.
-- 3) hddt_imported_invoice.reversed_voucher_no: dấu "đã đảo rồi", nhập lại
--    hóa đơn thay thế không tạo phiếu giảm lần hai.
-- =============================================

ALTER TABLE hddt_purchase_invoice ADD COLUMN tthai INTEGER NOT NULL DEFAULT 0;
ALTER TABLE hddt_purchase_invoice ADD COLUMN khhdgoc TEXT NOT NULL DEFAULT '';
ALTER TABLE hddt_purchase_invoice ADD COLUMN shdgoc TEXT NOT NULL DEFAULT '';
ALTER TABLE hddt_purchase_invoice ADD COLUMN tdlhdgoc TEXT NOT NULL DEFAULT '';

ALTER TABLE hddt_imported_invoice ADD COLUMN reversed_voucher_no TEXT NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS ix_hddt_imported_serial_no
    ON hddt_imported_invoice(khhdon, shdon);

-- Ảnh cache cũ: đọc lại tthai + gốc từ payload cổng đã lưu.
-- shdgoc là số trong JSON → cột TEXT nhận affinity, lưu '111' khớp shdon.
UPDATE hddt_purchase_invoice
   SET tthai     = COALESCE(json_extract(raw_json, '$.tthai'), 0),
       khhdgoc   = COALESCE(json_extract(raw_json, '$.khhdgoc'), ''),
       shdgoc    = COALESCE(CAST(json_extract(raw_json, '$.shdgoc') AS TEXT), ''),
       tdlhdgoc  = COALESCE(json_extract(raw_json, '$.tdlhdgoc'), '')
 WHERE raw_json <> '';

-- tthai 4/5/6 = đã bị thay thế / đã bị điều chỉnh / đã bị hủy: không phải việc
-- của kế toán, không được đếm vào "cần xử lý".
UPDATE hddt_purchase_invoice
   SET status = 'superseded',
       skip_reason = CASE tthai
           WHEN 4 THEN 'Hóa đơn đã bị thay thế — không nhập kho'
           WHEN 5 THEN 'Hóa đơn đã bị điều chỉnh — không nhập kho'
           WHEN 6 THEN 'Hóa đơn đã bị hủy — không nhập kho'
       END
 WHERE tthai IN (4, 5, 6);
