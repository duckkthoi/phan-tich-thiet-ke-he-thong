-- =====================================================================
-- Dữ liệu chạy thử module Nhận thanh toán từ khách hàng (CSDL riêng garaman_module2)
-- Lấy theo Hình 3.5 và kịch bản v3: nhân viên "NV bán hàng A", khách Nguyễn Văn Nam (KH01),
-- Trần Hoài Nam (KH02); HD001 (Chưa chốt, 720.000 đ), HD002 (Đã chốt, chưa thanh toán);
-- Bảo dưỡng phanh DV01, Dầu động cơ, Má phanh trước PT21.
-- Ghi chú dữ liệu thử (tài liệu không ghi):
--   * Tài khoản đăng nhập banhang / 123456 (mật khẩu lưu băm SHA-256).
--   * Địa chỉ của KH02 để trống.
--   * "Dầu động cơ" có id 3 (id 1 đã là DV01 vì tblItem dùng chung id) và tồn kho 30.
--   * Chi tiết của HD002 (1 x Kiểm tra phanh) và các mô tả/thời gian của DV02.
--
-- Dữ liệu bổ sung để test (ngoài Hình 3.5, không đổi các bản ghi ở trên):
--   * Tài khoản (đều mật khẩu 123456):
--       banhang2 - SalesStaff      -> đăng nhập được
--       kho01    - WarehouseStaff  -> bị từ chối (không phải nhân viên bán hàng)
--       quanly   - Manager         -> bị từ chối
--   * Trạng thái lịch hẹn (tài liệu không quy định giá trị): BOOKED, COMPLETED, CANCELLED.
--   * Trạng thái phiếu nhập (tài liệu không quy định giá trị): COMPLETED, PENDING.
--   * Tên khách bổ sung không chứa "nam" để kết quả tìm "Nam" vẫn đúng như Hình 3.5.
--   * Các tình huống test theo khách hàng:
--       KH03 Lê Thị Hồng    : HD003 PAID (từ lịch hẹn) + HD004 CONFIRMED -> thanh toán được
--       KH04 Phạm Quốc Bảo  : HD005 DRAFT bình thường -> chốt thành công (trừ kho bugi, 4 cái)
--                             HD006 DRAFT chưa có dòng nào -> chốt bị chặn; dùng để test "Bổ sung"
--       KH05 Hoàng Minh Đức : HD007 DRAFT có 3 ắc quy nhưng kho còn 2 -> chốt bị chặn (82.1)
--       KH06 Đặng Thu Trang : chỉ có HD008 PAID -> "không có hóa đơn chưa thanh toán"
--       KH07 Bùi Văn Hùng   : HD009 CONFIRMED + HD010 DRAFT -> danh sách nhiều hóa đơn
--       KH08 Ngô Thanh Tùng : chỉ có lịch hẹn sắp tới, chưa có hóa đơn nào
--   * Phụ tùng: PT27 Ắc quy còn 2 (sắp hết), PT28 Gạt mưa hết hàng (0) -> test vượt tồn kho
--     khi bổ sung; PT29 tên có ký tự "%" -> test escape LIKE.
--   * Một số dòng có unit_price khác giá hiện tại (giá tại thời điểm lập hóa đơn).
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

-- Thành viên / nhân viên
INSERT INTO tblMember (id, full_name, username, password, phone, email) VALUES
 (101, 'NV bán hàng A', 'banhang', SHA2('123456', 256), NULL, NULL),
 (102, 'Phạm Thu Hà', 'banhang2', SHA2('123456', 256), '0981112233', 'ha.pt@garaman.vn'),
 (103, 'Đỗ Minh Quân', 'kho01', SHA2('123456', 256), '0982223344', 'quan.dm@garaman.vn'),
 (104, 'Vũ Thị Lan', 'quanly', SHA2('123456', 256), '0983334455', 'lan.vt@garaman.vn');
INSERT INTO tblStaff (member_id, position) VALUES
 (101, 'SalesStaff'),
 (102, 'SalesStaff'),
 (103, 'WarehouseStaff'),
 (104, 'Manager');

-- Khách hàng (Customer kế thừa Member: tên đăng nhập = số điện thoại, mật khẩu 123456)
INSERT INTO tblMember (id, full_name, username, password, phone, email) VALUES
 (1, 'Nguyễn Văn Nam', '0901234567', SHA2('123456', 256), '0901234567', NULL),
 (2, 'Trần Hoài Nam', '0912345678', SHA2('123456', 256), '0912345678', NULL),
 (3, 'Lê Thị Hồng', '0987654321', SHA2('123456', 256), '0987654321', NULL),
 (4, 'Phạm Quốc Bảo', '0934567890', SHA2('123456', 256), '0934567890', NULL),
 (5, 'Hoàng Minh Đức', '0978123456', SHA2('123456', 256), '0978123456', NULL),
 (6, 'Đặng Thu Trang', '0965432187', SHA2('123456', 256), '0965432187', NULL),
 (7, 'Bùi Văn Hùng', '0923456781', SHA2('123456', 256), '0923456781', NULL),
 (8, 'Ngô Thanh Tùng', '0945612378', SHA2('123456', 256), '0945612378', NULL);
INSERT INTO tblCustomer (member_id, address) VALUES
 (1, 'Hà Nội'),
 (2, NULL),
 (3, 'Hà Đông, Hà Nội'),
 (4, 'Cầu Giấy, Hà Nội'),
 (5, 'Thanh Xuân, Hà Nội'),
 (6, NULL),
 (7, 'Long Biên, Hà Nội'),
 (8, 'Hoàng Mai, Hà Nội');

-- Kỹ thuật viên
INSERT INTO tblTechnician (id, full_name, phone) VALUES
 (1, 'Trịnh Văn Long', '0911000111'),
 (2, 'Lý Minh Tuấn',   '0911000222'),
 (3, 'Mai Xuân Khánh', '0911000333'),
 (4, 'Cao Đức Thịnh',  '0911000444');

-- Dịch vụ / phụ tùng
INSERT INTO tblItem (id, name, description, price) VALUES
 (1,  'Bảo dưỡng phanh', 'Kiểm tra, vệ sinh và bảo dưỡng hệ thống phanh; đánh giá tình trạng hoạt động của các bộ phận liên quan.', 400000),
 (2,  'Kiểm tra phanh',  'Kiểm tra tình trạng hệ thống phanh.', 150000),
 (3,  'Dầu động cơ',     NULL, 320000),
 (4,  'Thay dầu động cơ',            'Xả dầu cũ, thay dầu động cơ mới và kiểm tra rò rỉ.', 120000),
 (5,  'Bảo dưỡng định kỳ 10.000 km', 'Kiểm tra tổng thể, thay dầu, vệ sinh lọc gió, kiểm tra phanh và hệ thống treo theo mốc 10.000 km.', 600000),
 (6,  'Cân chỉnh thước lái',         'Cân chỉnh góc đặt bánh xe, khắc phục hiện tượng xe bị lệch lái.', 350000),
 (7,  'Vệ sinh điều hòa',            'Vệ sinh dàn lạnh, dàn nóng và kiểm tra áp suất ga điều hòa.', 450000),
 (8,  'Thay má phanh',               'Tháo lắp và thay má phanh, kiểm tra đĩa phanh.', 200000),
 (9,  'Kiểm tra tổng quát',          'Kiểm tra động cơ, hệ thống điện, phanh, lốp và gầm xe.', 250000),
 (21, 'Má phanh trước',  'Phụ tùng thay thế cho cụm phanh trước. Nhân viên gara tư vấn loại phù hợp với xe trước khi sử dụng.', 800000),
 (22, 'Má phanh sau',          'Phụ tùng thay thế cho cụm phanh sau.', 650000),
 (23, 'Lọc dầu',               'Lọc dầu động cơ, nên thay cùng mỗi lần thay dầu.', 150000),
 (24, 'Lọc gió động cơ',       'Lọc không khí nạp vào động cơ.', 180000),
 (25, 'Lọc gió điều hòa',      'Lọc bụi và mùi cho khoang cabin.', 220000),
 (26, 'Bugi đánh lửa',         'Bugi iridium, giá tính theo cái.', 120000),
 (27, 'Ắc quy 12V 60Ah',       'Ắc quy khô miễn bảo dưỡng, bảo hành 12 tháng.', 1850000),
 (28, 'Gạt mưa',               'Bộ lưỡi gạt mưa trước (2 cái).', 250000),
 (29, 'Nước làm mát 100% (1L)', 'Nước làm mát pha sẵn, không cần pha thêm nước.', 95000),
 (30, 'Dầu phanh DOT4',        'Dầu phanh chai 500 ml.', 140000);
INSERT INTO tblService (item_id, estimated_duration) VALUES
 (1, 60),
 (2, 30),
 (4, 30),
 (5, 120),
 (6, 45),
 (7, 60),
 (8, 45),
 (9, 60);
INSERT INTO tblSparePart (item_id, quantity_in_stock) VALUES
 (3, 30),
 (21, 12),
 (22, 8),
 (23, 25),
 (24, 15),
 (25, 10),
 (26, 40),
 (27, 2),
 (28, 0),
 (29, 20),
 (30, 18);

-- Nhà cung cấp và phiếu nhập
INSERT INTO tblSupplier (id, name, address, phone, contact_person) VALUES
 (1, 'Công ty CP Phụ tùng Ô tô Thành Công', 'Khu công nghiệp Quang Minh, Mê Linh, Hà Nội', '02438123456', 'Nguyễn Hữu Phúc'),
 (2, 'Công ty TNHH Dầu nhớt Việt',          'Số 12 Phạm Văn Đồng, Bắc Từ Liêm, Hà Nội',    '02437654321', 'Trần Thị Mai'),
 (3, 'Đại lý Ắc quy và Điện ô tô Minh Khoa', 'Số 88 Giải Phóng, Hai Bà Trưng, Hà Nội',     '0904555666',  'Phan Minh Khoa');
INSERT INTO tblImportReceipt (id, supplier_id, warehouse_staff_id, import_date, status) VALUES
 (1, 1, 103, '2026-10-01 09:00:00', 'COMPLETED'),
 (2, 2, 103, '2026-10-05 14:30:00', 'COMPLETED'),
 (3, 3, 103, '2026-11-13 10:00:00', 'PENDING');
INSERT INTO tblImportDetail (id, import_receipt_id, spare_part_id, quantity, import_price) VALUES
 (1, 1, 21, 10, 600000),
 (2, 1, 22, 10, 480000),
 (3, 1, 30, 20, 100000),
 (4, 1, 28, 10, 180000),
 (5, 2, 3,  40, 240000),
 (6, 2, 23, 30, 100000),
 (7, 2, 29, 24, 65000),
 (8, 3, 27, 5,  1500000),
 (9, 3, 26, 20, 85000);

-- Lịch hẹn
INSERT INTO tblAppointment (id, customer_id, appointment_time, status, note) VALUES
 (1, 3, '2026-11-02 08:00:00', 'COMPLETED', 'Bảo dưỡng định kỳ mốc 10.000 km'),
 (2, 4, '2026-11-13 08:00:00', 'COMPLETED', 'Xe bị lệch lái, máy rung khi chạy không tải'),
 (3, 5, '2026-11-10 09:30:00', 'COMPLETED', 'Xe khó nổ máy vào buổi sáng'),
 (4, 7, '2026-11-11 14:00:00', 'COMPLETED', 'Phanh sau có tiếng kêu khi dừng'),
 (5, 8, '2026-11-18 09:00:00', 'BOOKED',    'Vệ sinh điều hòa và kiểm tra tổng quát trước chuyến đi xa'),
 (6, 2, '2026-11-05 10:00:00', 'CANCELLED', 'Khách báo bận, hẹn lại sau'),
 (7, 1, '2026-11-20 08:30:00', 'BOOKED',    'Thay dầu định kỳ'),
 (8, 6, '2026-11-16 15:00:00', 'BOOKED',    NULL);
INSERT INTO tblAppointmentDetail (id, appointment_id, service_id) VALUES
 (1, 1, 5),
 (2, 2, 6),
 (3, 3, 9),
 (4, 4, 1),
 (5, 4, 2),
 (6, 5, 7),
 (7, 5, 9),
 (8, 6, 4),
 (9, 7, 4),
 (10, 8, 8);

-- Hóa đơn
INSERT INTO tblInvoice (id, customer_id, sales_staff_id, appointment_id, created_date, status, payment_date) VALUES
 (1, 1, 101, NULL, '2026-10-23 08:00:00', 'DRAFT', NULL),
 (2, 1, 101, NULL, '2026-10-21 08:00:00', 'CONFIRMED', NULL),
 (3, 3, 101, 1, '2026-11-02 09:00:00', 'PAID', '2026-11-02 11:30:00'),
 (4, 3, 102, NULL, '2026-11-12 14:00:00', 'CONFIRMED', NULL),
 (5, 4, 101, 2, '2026-11-13 08:30:00', 'DRAFT', NULL),
 (6, 4, 101, NULL, '2026-11-14 08:00:00', 'DRAFT', NULL),
 (7, 5, 102, 3, '2026-11-10 10:00:00', 'DRAFT', NULL),
 (8, 6, 101, NULL, '2026-10-15 16:00:00', 'PAID', '2026-10-15 17:10:00'),
 (9, 7, 102, 4, '2026-11-11 15:00:00', 'CONFIRMED', NULL),
 (10, 7, 101, NULL, '2026-11-14 09:15:00', 'DRAFT', NULL);
INSERT INTO tblInvoiceDetail (id, invoice_id, item_id, technician_id, quantity, unit_price) VALUES
 -- HD001 (Hình 3.5): 720.000 đ
 (1,  1, 1,  NULL, 1, 400000),
 (2,  1, 3,  NULL, 1, 320000),
 -- HD002: 150.000 đ
 (3,  2, 2,  NULL, 1, 150000),
 -- HD003 PAID: 1.070.000 đ
 (4,  3, 5,  1,    1, 600000),
 (5,  3, 23, NULL, 1, 150000),
 (6,  3, 3,  NULL, 1, 320000),
 -- HD004 CONFIRMED: 670.000 đ
 (7,  4, 7,  2,    1, 450000),
 (8,  4, 25, NULL, 1, 220000),
 -- HD005 DRAFT: 830.000 đ
 (9,  5, 6,  NULL, 1, 350000),
 (10, 5, 26, NULL, 4, 120000),
 -- HD006 DRAFT: chưa có dòng nào
 -- HD007 DRAFT: 3 ắc quy (kho còn 2), đơn giá cũ 1.800.000 -> 5.650.000 đ
 (11, 7, 9,  NULL, 1, 250000),
 (12, 7, 27, NULL, 3, 1800000),
 -- HD008 PAID: má phanh trước giá cũ 780.000 -> 980.000 đ
 (13, 8, 8,  3,    1, 200000),
 (14, 8, 21, NULL, 1, 780000),
 -- HD009 CONFIRMED: 1.340.000 đ
 (15, 9, 2,  4,    1, 150000),
 (16, 9, 1,  4,    1, 400000),
 (17, 9, 22, NULL, 1, 650000),
 (18, 9, 30, NULL, 1, 140000),
 -- HD010 DRAFT: 590.000 đ
 (19, 10, 4,  NULL, 1, 120000),
 (20, 10, 3,  NULL, 1, 320000),
 (21, 10, 23, NULL, 1, 150000);

-- Đưa bộ đếm AUTO_INCREMENT về MAX(id) + 1 (InnoDB tự nâng giá trị nhỏ hơn lên MAX(id) + 1)
ALTER TABLE tblMember            AUTO_INCREMENT = 1;
ALTER TABLE tblTechnician        AUTO_INCREMENT = 1;
ALTER TABLE tblItem              AUTO_INCREMENT = 1;
ALTER TABLE tblSupplier          AUTO_INCREMENT = 1;
ALTER TABLE tblImportReceipt     AUTO_INCREMENT = 1;
ALTER TABLE tblImportDetail      AUTO_INCREMENT = 1;
ALTER TABLE tblAppointment       AUTO_INCREMENT = 1;
ALTER TABLE tblAppointmentDetail AUTO_INCREMENT = 1;
ALTER TABLE tblInvoice           AUTO_INCREMENT = 1;
ALTER TABLE tblInvoiceDetail     AUTO_INCREMENT = 1;
