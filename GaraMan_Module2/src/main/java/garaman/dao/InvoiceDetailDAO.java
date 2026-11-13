package garaman.dao;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.DataSource;

import garaman.model.Invoice;
import garaman.model.InvoiceDetail;
import garaman.model.Item;
import garaman.model.Service;
import garaman.model.SparePart;

/**
 * InvoiceDetailDAO (Hình 4.7, Bảng 4.6): thêm dòng mới hoặc cộng số lượng;
 * kiểm tra DRAFT, số lượng dương và tồn kho. Thao tác này chưa trừ tồn kho.
 */
public class InvoiceDetailDAO extends DAO {

    private static final String SQL_LOCK_INVOICE =
            "SELECT status FROM tblInvoice WHERE id = ? FOR UPDATE";

    private static final String SQL_GET_ITEM =
            "SELECT i.id, i.name, i.description, i.price, "
            + "s.item_id AS service_id, s.estimated_duration, "
            + "sp.item_id AS spare_part_id, sp.quantity_in_stock "
            + "FROM tblItem i "
            + "LEFT JOIN tblService s ON s.item_id = i.id "
            + "LEFT JOIN tblSparePart sp ON sp.item_id = i.id "
            + "WHERE i.id = ?";

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
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try {
                String status;
                try (PreparedStatement ps = conn.prepareStatement(SQL_LOCK_INVOICE)) {
                    ps.setLong(1, invoiceId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new BusinessException("Hóa đơn không tồn tại");
                        }
                        status = rs.getString("status");
                    }
                }
                if (!Invoice.DRAFT.equals(status)) {
                    throw new BusinessException("Hóa đơn không còn ở trạng thái chưa chốt, không thể bổ sung");
                }

                Item item = readItem(conn, itemId);
                if (item == null) {
                    throw new BusinessException("Dịch vụ/phụ tùng không còn tồn tại");
                }

                Long lineId = null;
                int newQuantity = quantity;
                BigDecimal unitPrice = item.getPrice();
                try (PreparedStatement ps = conn.prepareStatement(SQL_GET_LINE)) {
                    ps.setLong(1, invoiceId);
                    ps.setLong(2, itemId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            lineId = rs.getLong("id");
                            newQuantity = rs.getInt("quantity") + quantity;
                            unitPrice = rs.getBigDecimal("unit_price");
                        }
                    }
                }

                if (item instanceof SparePart) {
                    int stock = ((SparePart) item).getQuantityInStock();
                    if (newQuantity > stock) {
                        throw new BusinessException("Số lượng vượt quá tồn kho (" + item.getName()
                                + " còn " + stock + ")");
                    }
                }

                if (lineId != null) {
                    try (PreparedStatement ps = conn.prepareStatement(SQL_UPDATE_LINE)) {
                        ps.setInt(1, newQuantity);
                        ps.setLong(2, lineId);
                        ps.executeUpdate();
                    }
                } else {
                    try (PreparedStatement ps = conn.prepareStatement(SQL_INSERT_LINE,
                            Statement.RETURN_GENERATED_KEYS)) {
                        ps.setLong(1, invoiceId);
                        ps.setLong(2, itemId);
                        ps.setInt(3, newQuantity);
                        ps.setBigDecimal(4, unitPrice);
                        ps.executeUpdate();
                        try (ResultSet keys = ps.getGeneratedKeys()) {
                            keys.next();
                            lineId = keys.getLong(1);
                        }
                    }
                }
                conn.commit();

                InvoiceDetail detail = new InvoiceDetail();
                detail.setId(lineId);
                detail.setQuantity(newQuantity);
                detail.setUnitPrice(unitPrice);
                detail.setItem(item);
                return detail;
            } catch (SQLException | BusinessException | RuntimeException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    /** Đọc mặt hàng (kèm bảng lớp con) trong cùng giao dịch; null nếu không tồn tại. */
    private static Item readItem(Connection conn, Long itemId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(SQL_GET_ITEM)) {
            ps.setLong(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }
                Item item;
                if (rs.getObject("service_id") != null) {
                    Service service = new Service();
                    service.setEstimatedDuration(rs.getInt("estimated_duration"));
                    item = service;
                } else if (rs.getObject("spare_part_id") != null) {
                    SparePart sparePart = new SparePart();
                    sparePart.setQuantityInStock(rs.getInt("quantity_in_stock"));
                    item = sparePart;
                } else {
                    return null;
                }
                item.setId(rs.getLong("id"));
                item.setName(rs.getString("name"));
                item.setDescription(rs.getString("description"));
                item.setPrice(rs.getBigDecimal("price"));
                return item;
            }
        }
    }
}
