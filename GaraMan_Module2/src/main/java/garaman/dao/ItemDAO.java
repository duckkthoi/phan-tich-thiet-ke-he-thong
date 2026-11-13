package garaman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import javax.sql.DataSource;

import garaman.model.Item;
import garaman.model.Service;
import garaman.model.SparePart;

/**
 * ItemDAO (Hình 4.5, Bảng 4.5): tìm dịch vụ/phụ tùng theo tên và đọc chi tiết.
 */
public class ItemDAO extends DAO {

    private static final String SELECT_ITEM =
            "SELECT i.id, i.name, i.description, i.price, "
            + "s.item_id AS service_id, s.estimated_duration, "
            + "sp.item_id AS spare_part_id, sp.quantity_in_stock "
            + "FROM tblItem i "
            + "LEFT JOIN tblService s ON s.item_id = i.id "
            + "LEFT JOIN tblSparePart sp ON sp.item_id = i.id ";

    private static final String SQL_SEARCH = SELECT_ITEM
            + "WHERE LOWER(i.name) LIKE LOWER(?) ESCAPE '!' "
            + "ORDER BY i.name, i.id";

    private static final String SQL_GET_DETAIL = SELECT_ITEM
            + "WHERE i.id = ?";

    public ItemDAO(DataSource dataSource) {
        super(dataSource);
    }

    /**
     * Tìm các dịch vụ/phụ tùng có tên chứa từ khóa (không phân biệt hoa thường),
     * sắp xếp theo tên rồi theo id.
     */
    public List<Item> search(String keyword) throws SQLException {
        List<Item> items = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_SEARCH)) {
            ps.setString(1, "%" + escapeLike(keyword) + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Item item = toItem(rs);
                    if (item != null) {
                        items.add(item);
                    }
                }
            }
        }
        return items;
    }

    /**
     * Đọc tblItem theo id và bảng lớp con (tblService hoặc tblSparePart) để xác định loại.
     */
    public Optional<Item> getDetail(Long itemId) throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_GET_DETAIL)) {
            ps.setLong(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.ofNullable(toItem(rs));
                }
            }
        }
        return Optional.empty();
    }

    /** Đóng gói bản ghi thành Service hoặc SparePart (Item là lớp trừu tượng). */
    private Item toItem(ResultSet rs) throws SQLException {
        if (rs.getObject("service_id") != null) {
            Service service = new Service();
            service.setId(rs.getLong("id"));
            service.setName(rs.getString("name"));
            service.setDescription(rs.getString("description"));
            service.setPrice(rs.getBigDecimal("price"));
            service.setEstimatedDuration(rs.getInt("estimated_duration"));
            return service;
        }
        if (rs.getObject("spare_part_id") != null) {
            SparePart sparePart = new SparePart();
            sparePart.setId(rs.getLong("id"));
            sparePart.setName(rs.getString("name"));
            sparePart.setDescription(rs.getString("description"));
            sparePart.setPrice(rs.getBigDecimal("price"));
            sparePart.setQuantityInStock(rs.getInt("quantity_in_stock"));
            return sparePart;
        }
        return null;
    }

    /** Escape kí tự đại diện của LIKE để từ khóa được so khớp nguyên văn. */
    private static String escapeLike(String keyword) {
        return keyword.replace("!", "!!").replace("%", "!%").replace("_", "!_");
    }
}
