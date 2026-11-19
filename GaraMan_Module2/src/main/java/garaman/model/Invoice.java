package garaman.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Lớp thực thể Invoice (Hình 3.6). status nhận ba giá trị DRAFT, CONFIRMED, PAID.
 * totalAmount là thuộc tính dẫn xuất, không lưu: tính bằng calculateTotal().
 */
public class Invoice {

    public static final String DRAFT = "DRAFT";
    public static final String CONFIRMED = "CONFIRMED";
    public static final String PAID = "PAID";

    private Long id;
    private LocalDateTime createdDate;
    private String status;
    private LocalDateTime paymentDate;
    private Customer customer;
    private SalesStaff salesStaff;
    private Appointment appointment;
    private List<InvoiceDetail> details = new ArrayList<>();

    public Invoice() {
    }

    /** Tổng tiền = tổng calculateSubtotal() của từng dòng, không truy cập CSDL. */
    public BigDecimal calculateTotal() {
        BigDecimal total = BigDecimal.ZERO;
        if (details != null) {
            for (InvoiceDetail detail : details) {
                total = total.add(detail.calculateSubtotal());
            }
        }
        return total;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(LocalDateTime createdDate) {
        this.createdDate = createdDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getPaymentDate() {
        return paymentDate;
    }

    public void setPaymentDate(LocalDateTime paymentDate) {
        this.paymentDate = paymentDate;
    }

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }

    public SalesStaff getSalesStaff() {
        return salesStaff;
    }

    public void setSalesStaff(SalesStaff salesStaff) {
        this.salesStaff = salesStaff;
    }

    public Appointment getAppointment() {
        return appointment;
    }

    public void setAppointment(Appointment appointment) {
        this.appointment = appointment;
    }

    public List<InvoiceDetail> getDetails() {
        return details;
    }

    public void setDetails(List<InvoiceDetail> details) {
        this.details = details;
    }
}
