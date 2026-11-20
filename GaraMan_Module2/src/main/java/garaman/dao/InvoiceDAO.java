package garaman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import javax.sql.DataSource;

import garaman.model.Customer;
import garaman.model.Invoice;
import garaman.model.InvoiceDetail;
import garaman.model.SalesStaff;
import garaman.model.Technician;

/**
 * InvoiceDAO (Hình 3.6, Bảng 3.6): đọc hóa đơn; chốt hóa đơn (trừ tồn kho, DRAFT → CONFIRMED)
 * và ghi nhận thanh toán (CONFIRMED → PAID) trong giao dịch.
 */
public class InvoiceDAO extends DAO {

    private static final String SQL_GET_UNPAID =
            "SELECT id, created_date, status FROM tblInvoice "
            + "WHERE customer_id = ? AND status IN ('DRAFT', 'CONFIRMED') "
            + "ORDER BY created_date, id";

    private static final String SQL_GET_HEADER =
            "SELECT inv.id, inv.created_date, inv.status, inv.payment_date, "
            + "c.member_id AS customer_id, cm.full_name AS customer_name, cm.phone AS customer_phone, "
            + "c.address AS customer_address, "
            + "m.id AS staff_id, m.full_name AS staff_name, m.username AS staff_username, "
            + "m.phone AS staff_phone, m.email AS staff_email, st.position AS staff_position "
            + "FROM tblInvoice inv "
            + "JOIN tblCustomer c ON c.member_id = inv.customer_id "
            + "JOIN tblMember cm ON cm.id = c.member_id "
            + "JOIN tblStaff st ON st.member_id = inv.sales_staff_id "
            + "JOIN tblMember m ON m.id = st.member_id "
            + "WHERE inv.id = ?";

    private static final String SQL_GET_DETAILS =
            "SELECT d.id, d.quantity, d.unit_price, "
            + "i.id AS item_id, i.name, i.description, i.price, "
            + "s.item_id AS service_id, s.estimated_duration, "
            + "sp.item_id AS spare_part_id, sp.quantity_in_stock, "
            + "t.id AS technician_id, t.full_name AS technician_name, t.phone AS technician_phone "
            + "FROM tblInvoiceDetail d "
            + "JOIN tblItem i ON i.id = d.item_id "
            + "LEFT JOIN tblService s ON s.item_id = i.id "
            + "LEFT JOIN tblSparePart sp ON sp.item_id = i.id "
            + "LEFT JOIN tblTechnician t ON t.id = d.technician_id "
            + "WHERE d.invoice_id = ? ORDER BY d.id";

    private static final String SQL_LOCK_INVOICE =
            "SELECT status FROM tblInvoice WHERE id = ? FOR UPDATE";

    private static final String SQL_COUNT_DETAILS =
            "SELECT COUNT(*) FROM tblInvoiceDetail WHERE invoice_id = ?";

    private static final String SQL_SPARE_PART_LINES =
            "SELECT d.item_id, d.quantity, i.name FROM tblInvoiceDetail d "
            + "JOIN tblSparePart sp ON sp.item_id = d.item_id "
            + "JOIN tblItem i ON i.id = d.item_id "
            + "WHERE d.invoice_id = ? ORDER BY d.item_id";

    private static final String SQL_LOCK_STOCK =
            "SELECT quantity_in_stock FROM tblSparePart WHERE item_id = ? FOR UPDATE";

    private static final String SQL_DEDUCT_STOCK =
            "UPDATE tblSparePart SET quantity_in_stock = quantity_in_stock - ? WHERE item_id = ?";

    private static final String SQL_SET_CONFIRMED =
            "UPDATE tblInvoice SET status = 'CONFIRMED' WHERE id = ? AND status = 'DRAFT'";

    private static final String SQL_SET_PAID =
            "UPDATE tblInvoice SET status = 'PAID', payment_date = ? WHERE id = ? AND status = 'CONFIRMED'";

    /** Một dòng phụ tùng của hóa đơn cần trừ tồn kho khi chốt. */
    private record SparePartLine(long itemId, int quantity, String name) {
    }

    public InvoiceDAO(DataSource dataSource) {
        super(dataSource);
    }

    /** Bước 17-21: các hóa đơn DRAFT/CONFIRMED của khách hàng, sắp theo ngày lập và id. */
    public List<Invoice> getUnpaidInvoice(Long customerId) throws SQLException {
        List<Invoice> invoices = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_GET_UNPAID)) {
            ps.setLong(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Invoice invoice = new Invoice();
                    invoice.setId(rs.getLong("id"));
                    invoice.setCreatedDate(toLocalDateTime(rs.getTimestamp("created_date")));
                    invoice.setStatus(rs.getString("status"));
                    invoices.add(invoice);
                }
            }
        }
        return invoices;
    }

    /** Bước 27-38: đọc tblInvoice, tblCustomer, tblInvoiceDetail và tblItem (kèm bảng lớp con). */
    public Optional<Invoice> getById(Long invoiceId) throws SQLException {
        try (Connection conn = getConnection()) {
            return readInvoice(conn, invoiceId);
        }
    }

    /**
     * Bước 82-85: trong một giao dịch, khóa hóa đơn, kiểm tra DRAFT và có ít nhất một dòng;
     * khóa và trừ tồn kho từng dòng phụ tùng theo thứ tự id; cập nhật status = CONFIRMED.
     * 82.1: thiếu tồn kho hoặc lỗi ghi → rollback toàn bộ, ném BusinessException.
     */
    public Invoice confirmInvoice(Long invoiceId) throws SQLException, BusinessException {
        return inTransaction(conn -> {
            if (!Invoice.DRAFT.equals(lockInvoice(conn, invoiceId))) {
                throw new BusinessException("Hóa đơn không còn ở trạng thái chưa chốt, không thể xác nhận hóa đơn");
            }
            if (countDetails(conn, invoiceId) == 0) {
                throw new BusinessException("Hóa đơn chưa có dịch vụ/phụ tùng nào, không thể xác nhận hóa đơn");
            }
            deductStock(conn, invoiceId);
            try (PreparedStatement ps = conn.prepareStatement(SQL_SET_CONFIRMED)) {
                ps.setLong(1, invoiceId);
                ps.executeUpdate();
            }
            return readInvoice(conn, invoiceId).orElseThrow();
        });
    }

    /**
     * Bước 93-96: trong một giao dịch, khóa hóa đơn, kiểm tra CONFIRMED, cập nhật status = PAID
     * và payment_date. 90.1: hóa đơn đã PAID → trả hóa đơn hiện hành, giữ nguyên ngày thanh toán.
     * 93.1: hóa đơn chưa chốt hoặc lỗi ghi → rollback, ném BusinessException.
     */
    public Invoice confirmPayment(Long invoiceId, LocalDateTime paymentDate) throws SQLException, BusinessException {
        return inTransaction(conn -> {
            String status = lockInvoice(conn, invoiceId);
            if (Invoice.PAID.equals(status)) {
                return readInvoice(conn, invoiceId).orElseThrow();
            }
            if (!Invoice.CONFIRMED.equals(status)) {
                throw new BusinessException("Hóa đơn chưa được chốt, không thể xác nhận thanh toán");
            }
            try (PreparedStatement ps = conn.prepareStatement(SQL_SET_PAID)) {
                ps.setTimestamp(1, Timestamp.valueOf(paymentDate));
                ps.setLong(2, invoiceId);
                if (ps.executeUpdate() != 1) {
                    throw new BusinessException("Không ghi nhận được thanh toán, vui lòng thử lại");
                }
            }
            return readInvoice(conn, invoiceId).orElseThrow();
        });
    }

    /**
     * Khóa bản ghi hóa đơn (SELECT ... FOR UPDATE) trong giao dịch đang mở và trả trạng thái hiện tại.
     * Dùng chung với InvoiceDetailDAO.
     */
    static String lockInvoice(Connection conn, Long invoiceId) throws SQLException, BusinessException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_LOCK_INVOICE)) {
            ps.setLong(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new BusinessException("Hóa đơn không tồn tại");
                }
                return rs.getString("status");
            }
        }
    }

    private static int countDetails(Connection conn, Long invoiceId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_COUNT_DETAILS)) {
            ps.setLong(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    /**
     * Duyệt từng dòng phụ tùng theo thứ tự id: khóa tblSparePart, kiểm tra tồn ≥ SL, trừ tồn
     * (cùng Connection). Khóa theo thứ tự cố định để hai giao dịch chốt đồng thời không bế tắc.
     */
    private static void deductStock(Connection conn, Long invoiceId) throws SQLException, BusinessException {
        for (SparePartLine line : readSparePartLines(conn, invoiceId)) {
            int stock;
            try (PreparedStatement ps = conn.prepareStatement(SQL_LOCK_STOCK)) {
                ps.setLong(1, line.itemId());
                try (ResultSet rs = ps.executeQuery()) {
                    rs.next();
                    stock = rs.getInt("quantity_in_stock");
                }
            }
            if (stock < line.quantity()) {
                throw new BusinessException("Phụ tùng " + line.name() + " không đủ tồn kho (còn "
                        + stock + ", cần " + line.quantity() + ")");
            }
            try (PreparedStatement ps = conn.prepareStatement(SQL_DEDUCT_STOCK)) {
                ps.setInt(1, line.quantity());
                ps.setLong(2, line.itemId());
                ps.executeUpdate();
            }
        }
    }

    private static List<SparePartLine> readSparePartLines(Connection conn, Long invoiceId) throws SQLException {
        List<SparePartLine> lines = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(SQL_SPARE_PART_LINES)) {
            ps.setLong(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lines.add(new SparePartLine(rs.getLong("item_id"), rs.getInt("quantity"), rs.getString("name")));
                }
            }
        }
        return lines;
    }

    /** Đóng gói hóa đơn: Customer, SalesStaff, từng InvoiceDetail (Item là Service/SparePart, Technician nếu có). */
    private static Optional<Invoice> readInvoice(Connection conn, Long invoiceId) throws SQLException {
        Invoice invoice;
        try (PreparedStatement ps = conn.prepareStatement(SQL_GET_HEADER)) {
            ps.setLong(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                invoice = toInvoiceHeader(rs);
            }
        }

        List<InvoiceDetail> details = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(SQL_GET_DETAILS)) {
            ps.setLong(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    InvoiceDetail detail = toInvoiceDetail(rs);
                    detail.setInvoice(invoice);
                    details.add(detail);
                }
            }
        }
        invoice.setDetails(details);
        return Optional.of(invoice);
    }

    private static Invoice toInvoiceHeader(ResultSet rs) throws SQLException {
        Customer customer = new Customer();
        customer.setId(rs.getLong("customer_id"));
        customer.setFullName(rs.getString("customer_name"));
        customer.setPhone(rs.getString("customer_phone"));
        customer.setAddress(rs.getString("customer_address"));

        SalesStaff salesStaff = new SalesStaff();
        salesStaff.setId(rs.getLong("staff_id"));
        salesStaff.setFullName(rs.getString("staff_name"));
        salesStaff.setUsername(rs.getString("staff_username"));
        salesStaff.setPhone(rs.getString("staff_phone"));
        salesStaff.setEmail(rs.getString("staff_email"));
        salesStaff.setPosition(rs.getString("staff_position"));

        Invoice invoice = new Invoice();
        invoice.setId(rs.getLong("id"));
        invoice.setCreatedDate(toLocalDateTime(rs.getTimestamp("created_date")));
        invoice.setStatus(rs.getString("status"));
        invoice.setPaymentDate(toLocalDateTime(rs.getTimestamp("payment_date")));
        invoice.setCustomer(customer);
        invoice.setSalesStaff(salesStaff);
        return invoice;
    }

    private static InvoiceDetail toInvoiceDetail(ResultSet rs) throws SQLException {
        InvoiceDetail detail = new InvoiceDetail();
        detail.setId(rs.getLong("id"));
        detail.setQuantity(rs.getInt("quantity"));
        detail.setUnitPrice(rs.getBigDecimal("unit_price"));
        detail.setItem(ItemDAO.toItem(rs, "item_id"));
        if (rs.getObject("technician_id") != null) {
            Technician technician = new Technician();
            technician.setId(rs.getLong("technician_id"));
            technician.setFullName(rs.getString("technician_name"));
            technician.setPhone(rs.getString("technician_phone"));
            detail.setTechnician(technician);
        }
        return detail;
    }

    private static LocalDateTime toLocalDateTime(Timestamp ts) {
        return ts == null ? null : ts.toLocalDateTime();
    }
}
