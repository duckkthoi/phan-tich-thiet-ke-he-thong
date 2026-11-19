package garaman.model;

import java.time.LocalDateTime;

/**
 * Lớp thực thể Appointment (Hình 3.6). Module nhận thanh toán không đọc/ghi lịch hẹn;
 * lớp chỉ giữ quan hệ Customer - Appointment - Invoice như biểu đồ lớp.
 */
public class Appointment {

    private Long id;
    private LocalDateTime appointmentTime;
    private String status;
    private String note;
    private Customer customer;
    private Invoice invoice;

    public Appointment() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getAppointmentTime() {
        return appointmentTime;
    }

    public void setAppointmentTime(LocalDateTime appointmentTime) {
        this.appointmentTime = appointmentTime;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }

    public Invoice getInvoice() {
        return invoice;
    }

    public void setInvoice(Invoice invoice) {
        this.invoice = invoice;
    }
}
