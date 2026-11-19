package garaman.model;

import java.util.ArrayList;
import java.util.List;

/**
 * Lớp thực thể Technician (Hình 3.6).
 */
public class Technician {

    private Long id;
    private String fullName;
    private String phone;
    private List<InvoiceDetail> invoiceDetails = new ArrayList<>();

    public Technician() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public List<InvoiceDetail> getInvoiceDetails() {
        return invoiceDetails;
    }

    public void setInvoiceDetails(List<InvoiceDetail> invoiceDetails) {
        this.invoiceDetails = invoiceDetails;
    }
}
