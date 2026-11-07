package garaman.dao;

import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;

/**
 * Lớp trừu tượng DAO (Hình 4.5): dùng chung nguồn kết nối (connection pool).
 */
public abstract class DAO {

    private final DataSource dataSource;

    protected DAO(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    protected Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }
}
