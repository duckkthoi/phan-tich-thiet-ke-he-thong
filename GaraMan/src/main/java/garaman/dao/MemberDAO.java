package garaman.dao;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HexFormat;
import java.util.Optional;

import javax.sql.DataSource;

import garaman.model.Customer;

/**
 * PHẦN NGOÀI MODULE TÌM KIẾM – đăng nhập của thành viên (gói member), dùng để tạo phiên
 * loggedInCustomer cho khách hàng trước khi vào module tìm kiếm. Mật khẩu được lưu dạng băm
 * SHA-256 (Bảng 3.1: password của Member được lưu dưới dạng băm).
 */
public class MemberDAO extends DAO {

    private static final String SQL_LOGIN =
            "SELECT m.id, m.full_name, m.username, m.password, m.phone, m.email, c.address "
            + "FROM tblMember m JOIN tblCustomer c ON c.member_id = m.id "
            + "WHERE m.username = ?";

    public MemberDAO(DataSource dataSource) {
        super(dataSource);
    }

    /** Trả về khách hàng nếu đúng tên đăng nhập, mật khẩu và tài khoản thuộc tblCustomer. */
    public Optional<Customer> checkCustomerLogin(String username, String password) throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_LOGIN)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                byte[] stored = rs.getString("password").getBytes(StandardCharsets.US_ASCII);
                byte[] given = sha256(password).getBytes(StandardCharsets.US_ASCII);
                if (!MessageDigest.isEqual(stored, given)) {
                    return Optional.empty();
                }
                Customer customer = new Customer();
                customer.setId(rs.getLong("id"));
                customer.setFullName(rs.getString("full_name"));
                customer.setUsername(rs.getString("username"));
                customer.setPhone(rs.getString("phone"));
                customer.setEmail(rs.getString("email"));
                customer.setAddress(rs.getString("address"));
                return Optional.of(customer);
            }
        }
    }

    private static String sha256(String value) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
