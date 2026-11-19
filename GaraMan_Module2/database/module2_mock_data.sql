-- =====================================================================
-- Mock data bổ sung cho CSDL garaman_module2 (chạy SAU module2_sample_data.sql)
-- Không sửa bản ghi nào của tệp mẫu; chỉ thêm bản ghi với id nối tiếp.
-- Ràng buộc: không tên khách mới nào chứa "nam" (so khớp không dấu), để tìm "Nam"
-- vẫn ra đúng KH01, KH02 như Hình 4.6.
-- Muốn reset: chạy lại module2_sample_data.sql rồi chạy tệp này.
--
-- Tài khoản thêm (mật khẩu 123456): banhang3 - SalesStaff, kho02 - WarehouseStaff.
-- Tình huống test theo khách hàng (tìm theo tên):
--   KH09 Vũ Đức Anh     : HD011 CONFIRMED (từ lịch hẹn, có KTV) + HD012 PAID cũ
--   KH20 Vũ Đức Anh     : trùng tên KH09, khác SĐT -> HD025 DRAFT (test phân biệt khách trùng tên)
--   KH10 Trịnh Thị Mai  : HD013 DRAFT 4 lốp (kho 16) -> chốt thành công, tổng 6.900.000 đ
--   KH11 Đinh Công Sơn  : HD014 DRAFT 2 cảm biến oxy (kho 1) -> chốt bị chặn
--   KH12 Lương Thị Hạnh : HD015, HD016 đều PAID -> "không có hóa đơn chưa thanh toán"
--   KH13 Phan Văn Toàn  : HD017 DRAFT + HD018 CONFIRMED + HD019 DRAFT -> danh sách 3 hóa đơn
--   KH14 Đỗ Thị Hương   : HD020 CONFIRMED (từ lịch hẹn) -> thanh toán
--   KH15 Nguyễn Hữu Thắng: chỉ HD021 DRAFT -> hệ thống mở thẳng hóa đơn
--   KH16 Tạ Minh Châu   : HD022 PAID
--   KH17 Hà Thị Thu     : chỉ có lịch hẹn sắp tới, chưa có hóa đơn
--   KH18 Kiều Văn Lực   : HD023 DRAFT 1 dây curoa -> bổ sung lại dây curoa để test cộng dồn SL
--   KH19 Lâm Bảo Ngọc   : HD024 CONFIRMED
--   KH21 Quách Gia Huy  : không có lịch hẹn hay hóa đơn nào
-- Phụ tùng mới: PT37 Cảm biến oxy kho 1, PT34 Giảm xóc kho 4 (test vượt tồn kho khi bổ sung).
-- =====================================================================
USE garaman_module2;

START TRANSACTION;

-- Thành viên / nhân viên
INSERT INTO tblMember (id, full_name, username, password, phone, email) VALUES
 (5, 'Lê Quang Huy',   'banhang3', SHA2('123456', 256), '0984445566', 'huy.lq@garaman.vn'),
 (6, 'Nguyễn Thị Thu', 'kho02',    SHA2('123456', 256), '0985556677', 'thu.nt@garaman.vn');
INSERT INTO tblStaff (member_id, position) VALUES
 (5, 'SalesStaff'),
 (6, 'WarehouseStaff');

-- Khách hàng
INSERT INTO tblCustomer (id, full_name, phone, address) VALUES
 (9,  'Vũ Đức Anh',       '0903111222', 'Đống Đa, Hà Nội'),
 (10, 'Trịnh Thị Mai',    '0914222333', 'Ba Đình, Hà Nội'),
 (11, 'Đinh Công Sơn',    '0925333444', 'Tây Hồ, Hà Nội'),
 (12, 'Lương Thị Hạnh',   '0936444555', NULL),
 (13, 'Phan Văn Toàn',    '0947555666', 'Hai Bà Trưng, Hà Nội'),
 (14, 'Đỗ Thị Hương',     '0958666777', 'Hà Đông, Hà Nội'),
 (15, 'Nguyễn Hữu Thắng', '0969777888', 'Bắc Từ Liêm, Hà Nội'),
 (16, 'Tạ Minh Châu',     '0970888999', 'Cầu Giấy, Hà Nội'),
 (17, 'Hà Thị Thu',       '0981999000', NULL),
 (18, 'Kiều Văn Lực',     '0902000111', 'Gia Lâm, Hà Nội'),
 (19, 'Lâm Bảo Ngọc',     '0913000222', 'Hoàn Kiếm, Hà Nội'),
 (20, 'Vũ Đức Anh',       '0924000333', 'Thanh Trì, Hà Nội'),
 (21, 'Quách Gia Huy',    '0935000444', NULL);

-- Kỹ thuật viên
INSERT INTO tblTechnician (id, full_name, phone) VALUES
 (5, 'Đoàn Văn Phú', '0911000555'),
 (6, 'Hồ Sỹ Bình',   '0911000666');

-- Dịch vụ / phụ tùng
INSERT INTO tblItem (id, name, description, price) VALUES
 (10, 'Cân bằng động bánh xe',  'Cân bằng bánh xe bằng máy, khắc phục rung vô lăng ở tốc độ cao.', 200000),
 (11, 'Nạp ga điều hòa',        'Hút chân không và nạp ga điều hòa theo đúng định lượng của nhà sản xuất.', 350000),
 (12, 'Vệ sinh kim phun',       'Vệ sinh kim phun và buồng đốt bằng dung dịch chuyên dụng.', 800000),
 (13, 'Thay nước làm mát',      'Xả nước làm mát cũ, súc rửa két nước và châm nước làm mát mới.', 180000),
 (14, 'Đảo lốp',                'Đảo vị trí lốp theo sơ đồ khuyến nghị để lốp mòn đều.', 100000),
 (15, 'Kiểm tra hệ thống điện', 'Kiểm tra ắc quy, máy phát, máy đề và hệ thống đèn.', 200000),
 (31, 'Lốp 205/55R16',          'Lốp không săm cho xe sedan hạng C, giá tính theo chiếc.', 1650000),
 (32, 'Bóng đèn pha H4',        'Bóng đèn halogen 12V 60/55W.', 180000),
 (33, 'Dây curoa tổng',         'Dây đai dẫn động máy phát, bơm trợ lực và máy nén điều hòa.', 450000),
 (34, 'Giảm xóc trước',         'Giảm xóc dầu cho bánh trước, giá tính theo chiếc.', 1250000),
 (35, 'Dầu hộp số ATF (1L)',    'Dầu hộp số tự động, chai 1 lít.', 210000),
 (36, 'Ga điều hòa R134a',      'Bình ga 1 kg.', 250000),
 (37, 'Cảm biến oxy',           'Cảm biến khí thải đặt trước bộ xúc tác.', 1450000),
 (38, 'Còi điện 12V',           'Còi sên âm thanh lớn, giá tính theo cặp.', 160000);
INSERT INTO tblService (item_id, estimated_duration) VALUES
 (10, 40), (11, 45), (12, 90), (13, 40), (14, 30), (15, 45);
INSERT INTO tblSparePart (item_id, quantity_in_stock) VALUES
 (31, 16), (32, 24), (33, 7), (34, 4), (35, 30), (36, 10), (37, 1), (38, 15);

-- Nhà cung cấp và phiếu nhập
INSERT INTO tblSupplier (id, name, address, phone, contact_person) VALUES
 (4, 'Công ty TNHH Lốp xe Hoàng Gia',      'Số 25 Nguyễn Văn Linh, Long Biên, Hà Nội', '02436888999', 'Lê Văn Hoàng'),
 (5, 'Công ty CP Điện lạnh Ô tô Bảo An',   'Số 9 Tam Trinh, Hoàng Mai, Hà Nội',        '02436777888', 'Đặng Bảo An');
INSERT INTO tblImportReceipt (id, supplier_id, warehouse_staff_id, import_date, status) VALUES
 (4, 4, 3, '2026-11-16 08:30:00', 'COMPLETED'),
 (5, 5, 6, '2026-11-17 09:00:00', 'COMPLETED'),
 (6, 1, 6, '2026-11-19 10:00:00', 'PENDING');
INSERT INTO tblImportDetail (id, import_receipt_id, spare_part_id, quantity, import_price) VALUES
 (10, 4, 31, 16, 1300000),
 (11, 4, 34, 4,  950000),
 (12, 5, 36, 10, 180000),
 (13, 5, 25, 10, 150000),
 (14, 5, 37, 2,  1100000),
 (15, 6, 32, 20, 120000),
 (16, 6, 33, 5,  320000),
 (17, 6, 38, 10, 110000);

-- Lịch hẹn
INSERT INTO tblAppointment (id, customer_id, appointment_time, status, note) VALUES
 (9,  9,  '2026-11-08 08:00:00', 'COMPLETED', 'Điều hòa không mát, có mùi'),
 (10, 10, '2026-11-16 09:00:00', 'COMPLETED', 'Thay lốp trước và sau'),
 (11, 14, '2026-11-12 13:30:00', 'COMPLETED', 'Xe hao xăng, nổ không êm'),
 (12, 13, '2026-11-14 08:00:00', 'COMPLETED', 'Bảo dưỡng định kỳ mốc 10.000 km'),
 (13, 17, '2026-11-24 09:30:00', 'BOOKED',    'Kiểm tra hệ thống điện, đèn pha mờ'),
 (14, 21, '2026-11-12 10:00:00', 'CANCELLED', 'Khách đổi lịch sang tuần sau'),
 (15, 19, '2026-11-17 14:00:00', 'COMPLETED', 'Thay nước làm mát, kiểm tra két nước'),
 (16, 12, '2026-11-26 08:00:00', 'BOOKED',    NULL);
INSERT INTO tblAppointmentDetail (id, appointment_id, service_id) VALUES
 (11, 9,  7),
 (12, 9,  11),
 (13, 10, 14),
 (14, 10, 10),
 (15, 11, 12),
 (16, 12, 5),
 (17, 13, 15),
 (18, 14, 9),
 (19, 15, 13),
 (20, 16, 4);

-- Hóa đơn
INSERT INTO tblInvoice (id, customer_id, sales_staff_id, appointment_id, created_date, status, payment_date) VALUES
 (11, 9,  1, 9,    '2026-11-08 09:30:00', 'CONFIRMED', NULL),
 (12, 9,  2, NULL, '2026-09-20 10:00:00', 'PAID',      '2026-09-20 11:45:00'),
 (13, 10, 5, 10,   '2026-11-16 10:00:00', 'DRAFT',     NULL),
 (14, 11, 1, NULL, '2026-11-15 15:00:00', 'DRAFT',     NULL),
 (15, 12, 2, NULL, '2026-10-02 08:30:00', 'PAID',      '2026-10-02 10:00:00'),
 (16, 12, 1, NULL, '2026-11-03 14:00:00', 'PAID',      '2026-11-03 15:20:00'),
 (17, 13, 1, 12,   '2026-11-14 09:00:00', 'DRAFT',     NULL),
 (18, 13, 2, NULL, '2026-11-01 16:00:00', 'CONFIRMED', NULL),
 (19, 13, 5, NULL, '2026-11-18 08:15:00', 'DRAFT',     NULL),
 (20, 14, 5, 11,   '2026-11-12 14:00:00', 'CONFIRMED', NULL),
 (21, 15, 1, NULL, '2026-11-17 10:30:00', 'DRAFT',     NULL),
 (22, 16, 2, NULL, '2026-10-28 09:00:00', 'PAID',      '2026-10-28 10:40:00'),
 (23, 18, 1, NULL, '2026-11-18 13:00:00', 'DRAFT',     NULL),
 (24, 19, 5, 15,   '2026-11-17 15:00:00', 'CONFIRMED', NULL),
 (25, 20, 2, NULL, '2026-11-19 08:00:00', 'DRAFT',     NULL);
INSERT INTO tblInvoiceDetail (id, invoice_id, item_id, technician_id, quantity, unit_price) VALUES
 -- HD011 CONFIRMED: 1.270.000 đ
 (23, 11, 7,  5,    1, 450000),
 (24, 11, 11, 5,    1, 350000),
 (25, 11, 36, NULL, 1, 250000),
 (26, 11, 25, NULL, 1, 220000),
 -- HD012 PAID: dầu động cơ giá cũ 300.000 -> 570.000 đ
 (27, 12, 4,  1,    1, 120000),
 (28, 12, 3,  NULL, 1, 300000),
 (29, 12, 23, NULL, 1, 150000),
 -- HD013 DRAFT: 6.900.000 đ
 (30, 13, 14, 6,    1, 100000),
 (31, 13, 10, 6,    1, 200000),
 (32, 13, 31, NULL, 4, 1650000),
 -- HD014 DRAFT: 2 cảm biến oxy, kho còn 1 -> chốt bị chặn; 3.150.000 đ
 (33, 14, 9,  NULL, 1, 250000),
 (34, 14, 37, NULL, 2, 1450000),
 -- HD015 PAID: 850.000 đ
 (35, 15, 8,  3,    1, 200000),
 (36, 15, 22, NULL, 1, 650000),
 -- HD016 PAID: 610.000 đ
 (37, 16, 32, NULL, 2, 180000),
 (38, 16, 9,  2,    1, 250000),
 -- HD017 DRAFT: 1.250.000 đ
 (39, 17, 5,  1,    1, 600000),
 (40, 17, 23, NULL, 1, 150000),
 (41, 17, 24, NULL, 1, 180000),
 (42, 17, 3,  NULL, 1, 320000),
 -- HD018 CONFIRMED: 2.850.000 đ
 (43, 18, 6,  4,    1, 350000),
 (44, 18, 34, NULL, 2, 1250000),
 -- HD019 DRAFT: 370.000 đ
 (45, 19, 29, NULL, 2, 95000),
 (46, 19, 13, NULL, 1, 180000),
 -- HD020 CONFIRMED: 1.280.000 đ
 (47, 20, 12, 3,    1, 800000),
 (48, 20, 26, NULL, 4, 120000),
 -- HD021 DRAFT: 440.000 đ
 (49, 21, 4,  NULL, 1, 120000),
 (50, 21, 3,  NULL, 1, 320000),
 -- HD022 PAID: 2.050.000 đ
 (51, 22, 15, 2,    1, 200000),
 (52, 22, 27, NULL, 1, 1850000),
 -- HD023 DRAFT: 450.000 đ
 (53, 23, 33, NULL, 1, 450000),
 -- HD024 CONFIRMED: 465.000 đ
 (54, 24, 13, 5,    1, 180000),
 (55, 24, 29, NULL, 3, 95000),
 -- HD025 DRAFT: 520.000 đ
 (56, 25, 32, NULL, 2, 180000),
 (57, 25, 38, NULL, 1, 160000);

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
