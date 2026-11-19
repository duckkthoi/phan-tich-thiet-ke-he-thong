package garaman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.sql.DataSource;

import garaman.model.Customer;

/**
 * CustomerDAO (Hình 3.6, Bảng 3.6): tìm khách hàng có full_name chứa từ khóa.
 */
public class CustomerDAO extends DAO {

    private static final String SQL_SEARCH =
            "SELECT id, full_name, phone, address FROM tblCustomer "
            + "WHERE LOWER(full_name) LIKE LOWER(?) ESCAPE '!' "
            + "ORDER BY full_name, id";

    public CustomerDAO(DataSource dataSource) {
        super(dataSource);
    }

    /** Bước 8-12: truy vấn tblCustomer với full_name LIKE từ khóa, đóng gói từng bản ghi thành Customer. */
    public List<Customer> searchCustomer(String name) throws SQLException {
        List<Customer> customers = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_SEARCH)) {
            ps.setString(1, likePattern(name));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Customer customer = new Customer();
                    customer.setId(rs.getLong("id"));
                    customer.setFullName(rs.getString("full_name"));
                    customer.setPhone(rs.getString("phone"));
                    customer.setAddress(rs.getString("address"));
                    customers.add(customer);
                }
            }
        }
        return customers;
    }
}
