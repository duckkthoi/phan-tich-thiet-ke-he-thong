-- =====================================================================
-- Dữ liệu chạy thử module Tìm kiếm thông tin dịch vụ/phụ tùng
-- Lấy theo Hình 3.3 (DV01, PT21, DV02). Mã hiển thị = tiền tố loại + id.
-- Ghi chú: tài liệu không ghi thời gian dự kiến và mô tả của DV02;
-- hai giá trị đó dưới đây chỉ là dữ liệu thử.
-- =====================================================================
USE garaman;

INSERT INTO tblItem (id, name, description, price) VALUES
 (1,  'Bảo dưỡng phanh', 'Kiểm tra, vệ sinh và bảo dưỡng hệ thống phanh; đánh giá tình trạng hoạt động của các bộ phận liên quan.', 400000),
 (2,  'Kiểm tra phanh',  'Kiểm tra tình trạng hệ thống phanh.', 150000),
 (21, 'Má phanh trước',  'Phụ tùng thay thế cho cụm phanh trước. Nhân viên gara tư vấn loại phù hợp với xe trước khi sử dụng.', 800000);

INSERT INTO tblService (item_id, estimated_duration) VALUES
 (1, 60),
 (2, 30);

INSERT INTO tblSparePart (item_id, quantity_in_stock) VALUES
 (21, 12);
