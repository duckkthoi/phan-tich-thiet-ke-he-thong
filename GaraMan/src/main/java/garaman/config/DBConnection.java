package garaman.config;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import javax.sql.DataSource;

import org.apache.tomcat.jdbc.pool.PoolProperties;

/**
 * Cấu hình kết nối CSDL (gói config, Hình 3.12): đọc db.properties và tạo
 * một connection pool dùng chung cho toàn hệ thống.
 */
public final class DBConnection {

    private static final String CONFIG_FILE = "db.properties";
    private static volatile DataSource dataSource;

    private DBConnection() {
    }

    public static DataSource getDataSource() {
        DataSource ds = dataSource;
        if (ds == null) {
            synchronized (DBConnection.class) {
                ds = dataSource;
                if (ds == null) {
                    ds = createDataSource();
                    dataSource = ds;
                }
            }
        }
        return ds;
    }

    private static DataSource createDataSource() {
        Properties props = new Properties();
        try (InputStream in = DBConnection.class.getResourceAsStream(CONFIG_FILE)) {
            if (in == null) {
                throw new IllegalStateException("Không tìm thấy tệp cấu hình " + CONFIG_FILE);
            }
            props.load(in);
        } catch (IOException e) {
            throw new IllegalStateException("Không đọc được tệp cấu hình " + CONFIG_FILE, e);
        }

        PoolProperties p = new PoolProperties();
        p.setDriverClassName(props.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        p.setUrl(props.getProperty("db.url"));
        p.setUsername(props.getProperty("db.username"));
        p.setPassword(props.getProperty("db.password", ""));
        p.setInitialSize(Integer.parseInt(props.getProperty("db.pool.initialSize", "2")));
        p.setMaxActive(Integer.parseInt(props.getProperty("db.pool.maxActive", "20")));
        p.setMaxIdle(Integer.parseInt(props.getProperty("db.pool.maxIdle", "10")));
        p.setMinIdle(Integer.parseInt(props.getProperty("db.pool.minIdle", "2")));
        p.setMaxWait(Integer.parseInt(props.getProperty("db.pool.maxWait", "10000")));
        p.setTestOnBorrow(true);
        p.setValidationQuery("SELECT 1");

        org.apache.tomcat.jdbc.pool.DataSource ds = new org.apache.tomcat.jdbc.pool.DataSource();
        ds.setPoolProperties(p);
        return ds;
    }
}
