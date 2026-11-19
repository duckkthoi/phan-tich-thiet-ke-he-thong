package garaman.model;

import java.util.ArrayList;
import java.util.List;

/**
 * Lớp thực thể SalesStaff kế thừa Staff (Hình 3.6); position trong tblStaff là "SalesStaff".
 */
public class SalesStaff extends Staff {

    /** Giá trị position của nhân viên bán hàng trong tblStaff (dùng để kiểm tra quyền khi đăng nhập và ở đầu mỗi trang). */
    public static final String POSITION = "SalesStaff";

    private List<Invoice> invoices = new ArrayList<>();

    public SalesStaff() {
    }

    public List<Invoice> getInvoices() {
        return invoices;
    }

    public void setInvoices(List<Invoice> invoices) {
        this.invoices = invoices;
    }
}
