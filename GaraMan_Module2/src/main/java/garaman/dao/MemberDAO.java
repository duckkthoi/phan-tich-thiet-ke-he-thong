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

import garaman.model.SalesStaff;

/**
 * PHẦN NGOÀI MODULE NHẬN THANH TOÁN – đăng nhập tối thiểu (thuộc chức năng của gói member),
 * chỉ để tạo phiên loggedInStaff cho nhân viên bán hàng. Mật khẩu được lưu dạng băm SHA-256
 * (Bảng 3.1: password của Member được lưu dưới dạng băm).
 */
public class MemberDAO extends DAO {

    private static final String SQL_LOGIN =
            "SELECT m.id, m.full_name, m.username, m.password, m.phone, m.email, s.position "
            + "FROM tblMember m JOIN tblStaff s ON s.member_id = m.id "
            + "WHERE m.username = ?";

    public MemberDAO(DataSource dataSource) {
        super(dataSource);
    }

    /** Trả về nhân viên bán hàng nếu đúng tên đăng nhập, mật khẩu và có position SalesStaff. */
    public Optional<SalesStaff> checkLogin(String username, String password) throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(SQL_LOGIN)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                byte[] stored = rs.getString("password").getBytes(StandardCharsets.US_ASCII);
                byte[] given = sha256(password).getBytes(StandardCharsets.US_ASCII);
                if (!MessageDigest.isEqual(stored, given)
                        || !SalesStaff.POSITION.equals(rs.getString("position"))) {
                    return Optional.empty();
                }
                SalesStaff staff = new SalesStaff();
                staff.setId(rs.getLong("id"));
                staff.setFullName(rs.getString("full_name"));
                staff.setUsername(rs.getString("username"));
                staff.setPhone(rs.getString("phone"));
                staff.setEmail(rs.getString("email"));
                staff.setPosition(rs.getString("position"));
                return Optional.of(staff);
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
