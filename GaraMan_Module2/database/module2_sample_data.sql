-- =====================================================================
-- Dữ liệu chạy thử module Nhận thanh toán từ khách hàng (CSDL riêng garaman_module2)
-- Lấy theo Hình 4.6 và kịch bản v3: nhân viên "NV bán hàng A", khách Nguyễn Văn Nam (KH01),
-- Trần Hoài Nam (KH02); HD001 (Chưa chốt, 720.000 đ), HD002 (Đã chốt, chưa thanh toán);
-- Bảo dưỡng phanh DV01, Dầu động cơ, Má phanh trước PT21.
-- Ghi chú dữ liệu thử (tài liệu không ghi):
--   * Tài khoản đăng nhập banhang / 123456 (mật khẩu lưu băm SHA-256).
--   * Địa chỉ của KH02 để trống.
--   * "Dầu động cơ" có id 3 (id 1 đã là DV01 vì tblItem dùng chung id) và tồn kho 30.
--   * Chi tiết của HD002 (1 x Kiểm tra phanh) và các mô tả/thời gian của DV02.
-- Chạy lại tệp này để đưa dữ liệu demo về trạng thái ban đầu.
-- =====================================================================
USE garaman_module2;

-- Xóa dữ liệu cũ (theo thứ tự khóa ngoại)
DELETE FROM tblInvoiceDetail;
DELETE FROM tblInvoice;
DELETE FROM tblAppointmentDetail;
DELETE FROM tblAppointment;
DELETE FROM tblImportDetail;
DELETE FROM tblImportReceipt;
DELETE FROM tblService;
DELETE FROM tblSparePart;
DELETE FROM tblItem;
DELETE FROM tblTechnician;
DELETE FROM tblCustomer;
DELETE FROM tblSupplier;
DELETE FROM tblStaff;
DELETE FROM tblMember;

-- Nhân viên bán hàng
INSERT INTO tblMember (id, full_name, username, password, phone, email) VALUES
 (1, 'NV bán hàng A', 'banhang', SHA2('123456', 256), NULL, NULL);
INSERT INTO tblStaff (member_id, position) VALUES
 (1, 'SalesStaff');

-- Khách hàng
INSERT INTO tblCustomer (id, full_name, phone, address) VALUES
 (1, 'Nguyễn Văn Nam', '0901234567', 'Hà Nội'),
 (2, 'Trần Hoài Nam',  '0912345678', NULL);

-- Dịch vụ / phụ tùng
INSERT INTO tblItem (id, name, description, price) VALUES
 (1,  'Bảo dưỡng phanh', 'Kiểm tra, vệ sinh và bảo dưỡng hệ thống phanh; đánh giá tình trạng hoạt động của các bộ phận liên quan.', 400000),
 (2,  'Kiểm tra phanh',  'Kiểm tra tình trạng hệ thống phanh.', 150000),
 (3,  'Dầu động cơ',     NULL, 320000),
 (21, 'Má phanh trước',  'Phụ tùng thay thế cho cụm phanh trước. Nhân viên gara tư vấn loại phù hợp với xe trước khi sử dụng.', 800000);
INSERT INTO tblService (item_id, estimated_duration) VALUES
 (1, 60),
 (2, 30);
INSERT INTO tblSparePart (item_id, quantity_in_stock) VALUES
 (3, 30),
 (21, 12);

-- Hóa đơn
INSERT INTO tblInvoice (id, customer_id, sales_staff_id, appointment_id, created_date, status, payment_date) VALUES
 (1, 1, 1, NULL, '2026-10-23 08:00:00', 'DRAFT',     NULL),
 (2, 1, 1, NULL, '2026-10-21 08:00:00', 'CONFIRMED', NULL);
INSERT INTO tblInvoiceDetail (id, invoice_id, item_id, technician_id, quantity, unit_price) VALUES
 (1, 1, 1, NULL, 1, 400000),
 (2, 1, 3, NULL, 1, 320000),
 (3, 2, 2, NULL, 1, 150000);

ALTER TABLE tblInvoiceDetail AUTO_INCREMENT = 4;
