-- =====================================================================
-- Mock data bổ sung cho CSDL garaman (chạy SAU module1_sample_data.sql)
-- Giữ nguyên 3 bản ghi của Hình 4.4 (DV01, DV02, PT21).
-- Ràng buộc: không tên dịch vụ/phụ tùng mới nào chứa "phanh", để tìm "phanh"
-- vẫn ra đúng 3 kết quả như Hình 4.4.
-- Từ khóa gợi ý để demo module 1:
--   "lọc"       -> 3 kết quả (Lọc dầu, Lọc gió động cơ, Lọc gió điều hòa)
--   "dầu"       -> nhiều kết quả, cả dịch vụ lẫn phụ tùng
--   "lốp"       -> Đảo lốp + 2 loại lốp
--   "điều hòa"  -> dịch vụ và phụ tùng điều hòa
--   "100%"      -> chỉ "Nước làm mát 100% (1L)" (test escape ký tự LIKE)
--   "xyz"       -> không có kết quả
--   PT28 Gạt mưa tồn kho 0, PT37/PT42 tồn kho 1 (xem chi tiết)
-- Mật khẩu mọi tài khoản: 123456 (SHA-256).
-- Trạng thái dùng chung với module 2: hóa đơn DRAFT/CONFIRMED/PAID,
-- lịch hẹn BOOKED/COMPLETED/CANCELLED, phiếu nhập COMPLETED/PENDING.
-- =====================================================================
USE garaman;

START TRANSACTION;

-- Dịch vụ / phụ tùng (id 1-20 là dịch vụ, 21 trở đi là phụ tùng)
INSERT INTO tblItem (id, name, description, price) VALUES
 (3,  'Thay dầu động cơ',             'Xả dầu cũ, thay dầu động cơ mới và kiểm tra rò rỉ.', 120000),
 (4,  'Bảo dưỡng định kỳ 5.000 km',   'Kiểm tra mức dầu, nước làm mát, áp suất lốp và hệ thống đèn theo mốc 5.000 km.', 450000),
 (5,  'Bảo dưỡng định kỳ 10.000 km',  'Kiểm tra tổng thể, thay dầu, vệ sinh lọc gió và kiểm tra hệ thống treo theo mốc 10.000 km.', 600000),
 (6,  'Cân chỉnh thước lái',          'Cân chỉnh góc đặt bánh xe, khắc phục hiện tượng xe bị lệch lái.', 350000),
 (7,  'Cân bằng động bánh xe',        'Cân bằng bánh xe bằng máy, khắc phục rung vô lăng ở tốc độ cao.', 200000),
 (8,  'Vệ sinh điều hòa',             'Vệ sinh dàn lạnh, dàn nóng và kiểm tra áp suất ga điều hòa.', 450000),
 (9,  'Nạp ga điều hòa',              'Hút chân không và nạp ga điều hòa theo đúng định lượng của nhà sản xuất.', 350000),
 (10, 'Kiểm tra tổng quát',           'Kiểm tra động cơ, hệ thống điện, lốp và gầm xe.', 250000),
 (11, 'Vệ sinh kim phun, buồng đốt',  'Vệ sinh kim phun và buồng đốt bằng dung dịch chuyên dụng, giúp xe nổ êm và tiết kiệm nhiên liệu.', 800000),
 (12, 'Thay nước làm mát',            'Xả nước làm mát cũ, súc rửa két nước và châm nước làm mát mới.', 180000),
 (13, 'Kiểm tra hệ thống điện',       'Kiểm tra ắc quy, máy phát, máy đề và hệ thống đèn.', 200000),
 (14, 'Đảo lốp',                      'Đảo vị trí lốp theo sơ đồ khuyến nghị để lốp mòn đều.', 100000),
 (15, 'Rửa xe và vệ sinh khoang máy', 'Rửa ngoài, hút bụi nội thất và vệ sinh khoang động cơ.', 150000),
 (16, 'Đánh bóng sơn',                'Đánh bóng toàn bộ thân xe, xóa vết xước nhẹ trên bề mặt sơn.', 1200000),
 (17, 'Sửa chữa hệ thống treo',       'Kiểm tra và thay thế giảm xóc, cao su, rotuyn của hệ thống treo.', 500000),
 (18, 'Thay dầu hộp số tự động',      'Thay dầu hộp số tự động bằng máy, kiểm tra hoạt động sang số.', 300000),
 (19, 'Phủ gầm chống gỉ',             'Vệ sinh gầm xe và phủ lớp chống gỉ, giảm tiếng ồn vọng lên khoang lái.', 900000),
 (20, 'Kiểm tra trước chuyến đi xa',  'Kiểm tra lốp, đèn, nước làm mát, dầu và các hệ thống an toàn trước hành trình dài.', 300000),
 (22, 'Dầu động cơ 5W-30 (4L)',       'Dầu tổng hợp toàn phần, can 4 lít.', 950000),
 (23, 'Lọc dầu',                      'Lọc dầu động cơ, nên thay cùng mỗi lần thay dầu.', 150000),
 (24, 'Lọc gió động cơ',              'Lọc không khí nạp vào động cơ.', 180000),
 (25, 'Lọc gió điều hòa',             'Lọc bụi và mùi cho khoang cabin.', 220000),
 (26, 'Bugi đánh lửa',                'Bugi iridium, giá tính theo cái.', 120000),
 (27, 'Ắc quy 12V 60Ah',              'Ắc quy khô miễn bảo dưỡng, bảo hành 12 tháng.', 1850000),
 (28, 'Gạt mưa',                      'Bộ lưỡi gạt mưa trước (2 cái).', 250000),
 (29, 'Nước làm mát 100% (1L)',       'Nước làm mát pha sẵn, không cần pha thêm nước.', 95000),
 (30, 'Lốp 205/55R16',                'Lốp không săm cho xe sedan hạng C, giá tính theo chiếc.', 1650000),
 (31, 'Lốp 185/65R15',                'Lốp không săm cho xe hạng B, giá tính theo chiếc.', 1350000),
 (32, 'Bóng đèn pha H4',              'Bóng đèn halogen 12V 60/55W.', 180000),
 (33, 'Dây curoa tổng',               'Dây đai dẫn động máy phát, bơm trợ lực và máy nén điều hòa.', 450000),
 (34, 'Giảm xóc trước',               'Giảm xóc dầu cho bánh trước, giá tính theo chiếc.', 1250000),
 (35, 'Rotuyn lái ngoài',             'Rotuyn đầu thước lái, giá tính theo chiếc.', 380000),
 (36, 'Dầu hộp số ATF (1L)',          'Dầu hộp số tự động, chai 1 lít.', 210000),
 (37, 'Cảm biến oxy',                 'Cảm biến khí thải đặt trước bộ xúc tác.', 1450000),
 (38, 'Bơm nước làm mát',             'Bơm tuần hoàn nước làm mát động cơ.', 980000),
 (39, 'Còi điện 12V',                 'Còi sên âm thanh lớn, giá tính theo cặp.', 160000),
 (40, 'Ga điều hòa R134a',            'Bình ga 1 kg.', 250000),
 (41, 'Dung dịch vệ sinh kim phun',   'Chai 300 ml, đổ trực tiếp vào bình nhiên liệu.', 165000),
 (42, 'Gương chiếu hậu bên phải',     'Gương chiếu hậu chỉnh điện, chưa sơn.', 850000),
 (43, 'Cầu chì 10A (vỉ 10 cái)',      'Cầu chì lưỡi loại nhỏ.', 30000);

INSERT INTO tblService (item_id, estimated_duration) VALUES
 (3, 30), (4, 90), (5, 120), (6, 45), (7, 40), (8, 60), (9, 45), (10, 60), (11, 90),
 (12, 40), (13, 45), (14, 30), (15, 45), (16, 180), (17, 120), (18, 45), (19, 150), (20, 60);

INSERT INTO tblSparePart (item_id, quantity_in_stock) VALUES
 (22, 30), (23, 25), (24, 15), (25, 10), (26, 40), (27, 6), (28, 0), (29, 20), (30, 16), (31, 12),
 (32, 24), (33, 7), (34, 4), (35, 6), (36, 30), (37, 1), (38, 2), (39, 15), (40, 10), (41, 20),
 (42, 1), (43, 50);

-- Thành viên / nhân viên
INSERT INTO tblMember (id, full_name, username, password, phone, email) VALUES
 (1, 'NV bán hàng A',  'banhang',  SHA2('123456', 256), NULL, NULL),
 (2, 'Phạm Thu Hà',    'banhang2', SHA2('123456', 256), '0981112233', 'ha.pt@garaman.vn'),
 (3, 'Đỗ Minh Quân',   'kho01',    SHA2('123456', 256), '0982223344', 'quan.dm@garaman.vn'),
 (4, 'Vũ Thị Lan',     'quanly',   SHA2('123456', 256), '0983334455', 'lan.vt@garaman.vn'),
 (5, 'Lê Quang Huy',   'banhang3', SHA2('123456', 256), '0984445566', 'huy.lq@garaman.vn'),
 (6, 'Nguyễn Thị Thu', 'kho02',    SHA2('123456', 256), '0985556677', 'thu.nt@garaman.vn');
INSERT INTO tblStaff (member_id, position) VALUES
 (1, 'SalesStaff'), (2, 'SalesStaff'), (3, 'WarehouseStaff'), (4, 'Manager'), (5, 'SalesStaff'), (6, 'WarehouseStaff');

-- Khách hàng
INSERT INTO tblCustomer (id, full_name, phone, address) VALUES
 (1,  'Nguyễn Văn Nam', '0901234567', 'Hà Nội'),
 (2,  'Trần Hoài Nam',  '0912345678', NULL),
 (3,  'Lê Thị Hồng',    '0987654321', 'Hà Đông, Hà Nội'),
 (4,  'Phạm Quốc Bảo',  '0934567890', 'Cầu Giấy, Hà Nội'),
 (5,  'Hoàng Minh Đức', '0978123456', 'Thanh Xuân, Hà Nội'),
 (6,  'Đặng Thu Trang', '0965432187', NULL),
 (7,  'Bùi Văn Hùng',   '0923456781', 'Long Biên, Hà Nội'),
 (8,  'Ngô Thanh Tùng', '0945612378', 'Hoàng Mai, Hà Nội'),
 (9,  'Vũ Đức Anh',     '0903111222', 'Đống Đa, Hà Nội'),
 (10, 'Trịnh Thị Mai',  '0914222333', 'Ba Đình, Hà Nội'),
 (11, 'Đinh Công Sơn',  '0925333444', 'Tây Hồ, Hà Nội'),
 (12, 'Lương Thị Hạnh', '0936444555', NULL);

-- Kỹ thuật viên
INSERT INTO tblTechnician (id, full_name, phone) VALUES
 (1, 'Trịnh Văn Long', '0911000111'),
 (2, 'Lý Minh Tuấn',   '0911000222'),
 (3, 'Mai Xuân Khánh', '0911000333'),
 (4, 'Cao Đức Thịnh',  '0911000444'),
 (5, 'Đoàn Văn Phú',   '0911000555');

-- Nhà cung cấp và phiếu nhập
INSERT INTO tblSupplier (id, name, address, phone, contact_person) VALUES
 (1, 'Công ty CP Phụ tùng Ô tô Thành Công',  'Khu công nghiệp Quang Minh, Mê Linh, Hà Nội', '02438123456', 'Nguyễn Hữu Phúc'),
 (2, 'Công ty TNHH Dầu nhớt Việt',           'Số 12 Phạm Văn Đồng, Bắc Từ Liêm, Hà Nội',    '02437654321', 'Trần Thị Mai'),
 (3, 'Đại lý Ắc quy và Điện ô tô Minh Khoa', 'Số 88 Giải Phóng, Hai Bà Trưng, Hà Nội',      '0904555666',  'Phan Minh Khoa'),
 (4, 'Công ty TNHH Lốp xe Hoàng Gia',        'Số 25 Nguyễn Văn Linh, Long Biên, Hà Nội',    '02436888999', 'Lê Văn Hoàng');
INSERT INTO tblImportReceipt (id, supplier_id, warehouse_staff_id, import_date, status) VALUES
 (1, 1, 3, '2026-10-01 09:00:00', 'COMPLETED'),
 (2, 2, 3, '2026-10-05 14:30:00', 'COMPLETED'),
 (3, 3, 6, '2026-11-13 10:00:00', 'PENDING'),
 (4, 4, 6, '2026-11-16 08:30:00', 'COMPLETED');
INSERT INTO tblImportDetail (id, import_receipt_id, spare_part_id, quantity, import_price) VALUES
 (1,  1, 21, 10, 600000),
 (2,  1, 34, 4,  950000),
 (3,  1, 35, 6,  280000),
 (4,  1, 28, 10, 180000),
 (5,  2, 22, 40, 720000),
 (6,  2, 23, 30, 100000),
 (7,  2, 36, 30, 150000),
 (8,  2, 29, 24, 65000),
 (9,  3, 27, 5,  1500000),
 (10, 3, 26, 20, 85000),
 (11, 3, 32, 20, 120000),
 (12, 4, 30, 16, 1300000),
 (13, 4, 31, 12, 1050000);

-- Lịch hẹn
INSERT INTO tblAppointment (id, customer_id, appointment_time, status, note) VALUES
 (1,  3,  '2026-11-02 08:00:00', 'COMPLETED', 'Bảo dưỡng định kỳ mốc 10.000 km'),
 (2,  4,  '2026-11-13 08:00:00', 'COMPLETED', 'Xe bị lệch lái, rung vô lăng'),
 (3,  5,  '2026-11-10 09:30:00', 'COMPLETED', 'Xe khó nổ máy vào buổi sáng'),
 (4,  7,  '2026-11-11 14:00:00', 'COMPLETED', 'Phanh sau có tiếng kêu khi dừng'),
 (5,  8,  '2026-11-25 09:00:00', 'BOOKED',    'Vệ sinh điều hòa trước chuyến đi xa'),
 (6,  2,  '2026-11-05 10:00:00', 'CANCELLED', 'Khách báo bận, hẹn lại sau'),
 (7,  1,  '2026-11-20 08:30:00', 'BOOKED',    'Thay dầu định kỳ'),
 (8,  9,  '2026-11-15 13:30:00', 'COMPLETED', 'Điều hòa không mát'),
 (9,  10, '2026-11-22 10:00:00', 'BOOKED',    NULL),
 (10, 11, '2026-11-18 15:00:00', 'COMPLETED', 'Xe hao xăng, nổ không êm');
INSERT INTO tblAppointmentDetail (id, appointment_id, service_id) VALUES
 (1, 1, 5), (2, 2, 6), (3, 2, 7), (4, 3, 13), (5, 4, 1), (6, 4, 2), (7, 5, 8), (8, 5, 20),
 (9, 6, 3), (10, 7, 3), (11, 8, 8), (12, 8, 9), (13, 9, 14), (14, 9, 7), (15, 10, 11);

-- Hóa đơn
INSERT INTO tblInvoice (id, customer_id, sales_staff_id, appointment_id, created_date, status, payment_date) VALUES
 (1,  1,  1, NULL, '2026-10-23 08:00:00', 'DRAFT',     NULL),
 (2,  1,  1, NULL, '2026-10-21 08:00:00', 'CONFIRMED', NULL),
 (3,  3,  1, 1,    '2026-11-02 09:00:00', 'PAID',      '2026-11-02 11:30:00'),
 (4,  4,  2, 2,    '2026-11-13 08:30:00', 'CONFIRMED', NULL),
 (5,  5,  2, 3,    '2026-11-10 10:00:00', 'PAID',      '2026-11-10 12:15:00'),
 (6,  6,  1, NULL, '2026-10-15 16:00:00', 'PAID',      '2026-10-15 17:10:00'),
 (7,  7,  2, 4,    '2026-11-11 15:00:00', 'CONFIRMED', NULL),
 (8,  9,  5, 8,    '2026-11-15 14:00:00', 'PAID',      '2026-11-15 16:00:00'),
 (9,  11, 5, 10,   '2026-11-18 15:30:00', 'DRAFT',     NULL),
 (10, 12, 1, NULL, '2026-11-17 09:00:00', 'DRAFT',     NULL);
INSERT INTO tblInvoiceDetail (id, invoice_id, item_id, technician_id, quantity, unit_price) VALUES
 (1,  1,  1,  NULL, 1, 400000),
 (2,  1,  22, NULL, 1, 950000),
 (3,  2,  2,  NULL, 1, 150000),
 (4,  3,  5,  1,    1, 600000),
 (5,  3,  23, NULL, 1, 150000),
 (6,  3,  22, NULL, 1, 950000),
 (7,  4,  6,  2,    1, 350000),
 (8,  4,  7,  2,    1, 200000),
 (9,  4,  35, NULL, 2, 380000),
 (10, 5,  13, 3,    1, 200000),
 (11, 5,  27, NULL, 1, 1800000),
 (12, 6,  21, NULL, 1, 780000),
 (13, 6,  15, 4,    1, 150000),
 (14, 7,  1,  4,    1, 400000),
 (15, 7,  2,  4,    1, 150000),
 (16, 7,  21, NULL, 1, 800000),
 (17, 8,  8,  5,    1, 450000),
 (18, 8,  9,  5,    1, 350000),
 (19, 8,  40, NULL, 1, 250000),
 (20, 8,  25, NULL, 1, 220000),
 (21, 9,  11, 3,    1, 800000),
 (22, 9,  41, NULL, 1, 165000),
 (23, 9,  26, NULL, 4, 120000),
 (24, 10, 14, NULL, 1, 100000),
 (25, 10, 30, NULL, 2, 1650000);

COMMIT;

-- Đưa bộ đếm AUTO_INCREMENT về MAX(id) + 1
ALTER TABLE tblMember            AUTO_INCREMENT = 1;
ALTER TABLE tblCustomer          AUTO_INCREMENT = 1;
ALTER TABLE tblTechnician        AUTO_INCREMENT = 1;
ALTER TABLE tblItem              AUTO_INCREMENT = 1;
ALTER TABLE tblSupplier          AUTO_INCREMENT = 1;
ALTER TABLE tblImportReceipt     AUTO_INCREMENT = 1;
ALTER TABLE tblImportDetail      AUTO_INCREMENT = 1;
ALTER TABLE tblAppointment       AUTO_INCREMENT = 1;
ALTER TABLE tblAppointmentDetail AUTO_INCREMENT = 1;
ALTER TABLE tblInvoice           AUTO_INCREMENT = 1;
ALTER TABLE tblInvoiceDetail     AUTO_INCREMENT = 1;
