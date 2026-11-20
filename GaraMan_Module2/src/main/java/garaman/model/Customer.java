package garaman.model;

import java.util.ArrayList;
import java.util.List;

/**
 * Lớp thực thể Customer (Hình 3.6): khách hàng là thành viên, kế thừa Member
 * (họ tên, tên đăng nhập, mật khẩu, số điện thoại, email) và có thêm địa chỉ.
 */
public class Customer extends Member {

    private String address;
    private List<Appointment> appointments = new ArrayList<>();
    private List<Invoice> invoices = new ArrayList<>();

    public Customer() {
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public List<Appointment> getAppointments() {
        return appointments;
    }

    public void setAppointments(List<Appointment> appointments) {
        this.appointments = appointments;
    }

    public List<Invoice> getInvoices() {
        return invoices;
    }

    public void setInvoices(List<Invoice> invoices) {
        this.invoices = invoices;
    }
}
