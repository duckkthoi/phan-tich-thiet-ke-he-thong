package garaman.dao;

import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;

/**
 * Lớp trừu tượng DAO (Hình 3.6): dùng chung nguồn kết nối (connection pool),
 * mẫu tìm kiếm LIKE và khuôn chạy giao dịch cho các lớp con.
 */
public abstract class DAO {

    /** Phần việc chạy trong một giao dịch, dùng chung một Connection. */
    @FunctionalInterface
    protected interface TransactionWork<T> {
        T execute(Connection conn) throws SQLException, BusinessException;
    }

    private final DataSource dataSource;

    protected DAO(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    protected Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    /**
     * Chạy work trong một giao dịch: setAutoCommit(false), commit khi xong;
     * bất kỳ lỗi nào (SQLException, BusinessException, RuntimeException) đều rollback toàn bộ rồi ném lại.
     */
    protected <T> T inTransaction(TransactionWork<T> work) throws SQLException, BusinessException {
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try {
                T result = work.execute(conn);
                conn.commit();
                return result;
            } catch (SQLException | BusinessException | RuntimeException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
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
