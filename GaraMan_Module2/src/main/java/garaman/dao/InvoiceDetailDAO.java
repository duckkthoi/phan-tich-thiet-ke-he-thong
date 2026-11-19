package garaman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.DataSource;

import garaman.model.Invoice;
import garaman.model.InvoiceDetail;
import garaman.model.Item;
import garaman.model.SparePart;

/**
 * InvoiceDetailDAO (Hình 3.6, Bảng 3.6): thêm dòng mới hoặc cộng số lượng;
 * kiểm tra DRAFT, số lượng dương và tồn kho. Thao tác này chưa trừ tồn kho.
 */
public class InvoiceDetailDAO extends DAO {

    private static final String SQL_GET_LINE =
            "SELECT id, quantity, unit_price FROM tblInvoiceDetail WHERE invoice_id = ? AND item_id = ?";

    private static final String SQL_UPDATE_LINE =
            "UPDATE tblInvoiceDetail SET quantity = ? WHERE id = ?";

    private static final String SQL_INSERT_LINE =
            "INSERT INTO tblInvoiceDetail (invoice_id, item_id, technician_id, quantity, unit_price) "
            + "VALUES (?, ?, NULL, ?, ?)";

    public InvoiceDetailDAO(DataSource dataSource) {
        super(dataSource);
    }

    /**
     * Bước 60-64: trong một giao dịch, khóa hóa đơn, kiểm tra DRAFT, kiểm tra số lượng không vượt
     * tồn kho (nếu là phụ tùng); dòng đã có thì cộng số lượng, chưa có thì thêm dòng mới với đơn giá
     * lấy từ Item.price; commit. 60.1: vi phạm → rollback, ném BusinessException.
     */
    public InvoiceDetail addDetail(Long invoiceId, Long itemId, Integer quantity)
            throws SQLException, BusinessException {
        if (quantity == null || quantity < 1) {
            throw new BusinessException("Số lượng không hợp lệ");
        }
        return inTransaction(conn -> {
            if (!Invoice.DRAFT.equals(InvoiceDAO.lockInvoice(conn, invoiceId))) {
                throw new BusinessException("Hóa đơn không còn ở trạng thái chưa chốt, không thể bổ sung");
            }
            Item item = ItemDAO.readItem(conn, itemId);
            if (item == null) {
                throw new BusinessException("Dịch vụ/phụ tùng không còn tồn tại");
            }

            // Mặt hàng đã có trên hóa đơn: cộng dồn số lượng, giữ đơn giá cũ của dòng
            InvoiceDetail detail = findLine(conn, invoiceId, itemId);
            if (detail == null) {
                detail = new InvoiceDetail();
                detail.setQuantity(quantity);
                detail.setUnitPrice(item.getPrice());
            } else {
                detail.setQuantity(detail.getQuantity() + quantity);
            }
            detail.setItem(item);

            if (item instanceof SparePart sparePart && detail.getQuantity() > sparePart.getQuantityInStock()) {
                throw new BusinessException("Số lượng vượt quá tồn kho (" + item.getName()
                        + " còn " + sparePart.getQuantityInStock() + ")");
            }

            if (detail.getId() != null) {
                updateQuantity(conn, detail);
            } else {
                insertLine(conn, invoiceId, detail);
            }
            return detail;
        });
    }

    /** Dòng chi tiết hiện có của mặt hàng trên hóa đơn (chỉ id, quantity, unitPrice); null nếu chưa có. */
    private static InvoiceDetail findLine(Connection conn, Long invoiceId, Long itemId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_GET_LINE)) {
            ps.setLong(1, invoiceId);
            ps.setLong(2, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                InvoiceDetail line = new InvoiceDetail();
                line.setId(rs.getLong("id"));
                line.setQuantity(rs.getInt("quantity"));
                line.setUnitPrice(rs.getBigDecimal("unit_price"));
                return line;
            }
        }
    }

    private static void updateQuantity(Connection conn, InvoiceDetail detail) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_UPDATE_LINE)) {
            ps.setInt(1, detail.getQuantity());
            ps.setLong(2, detail.getId());
            ps.executeUpdate();
        }
    }

    /** Thêm dòng mới và gán id sinh tự động cho detail. */
    private static void insertLine(Connection conn, Long invoiceId, InvoiceDetail detail) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_INSERT_LINE, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, invoiceId);
            ps.setLong(2, detail.getItem().getId());
            ps.setInt(3, detail.getQuantity());
            ps.setBigDecimal(4, detail.getUnitPrice());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                detail.setId(keys.getLong(1));
            }
        }
    }
}
