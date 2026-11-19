package garaman.dao;

import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;

/**
 * Lớp trừu tượng DAO (Hình 3.4): dùng chung nguồn kết nối (connection pool).
 */
public abstract class DAO {

    private final DataSource dataSource;

    protected DAO(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    protected Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    /**
     * Mẫu "%từ khóa%" cho LIKE ... ESCAPE '!': các kí tự đại diện trong từ khóa được thoát
     * để so khớp nguyên văn.
     */
    protected static String likePattern(String keyword) {
        String escaped = keyword.replace("!", "!!").replace("%", "!%").replace("_", "!_");
        return "%" + escaped + "%";
    }
}
