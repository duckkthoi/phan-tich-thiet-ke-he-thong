package garaman.model;

/**
 * Lớp thực thể Customer (Hình 3.1, Hình 3.4): khách hàng là thành viên, kế thừa Member
 * (họ tên, tên đăng nhập, mật khẩu, số điện thoại, email) và có thêm địa chỉ.
 */
public class Customer extends Member {

    private String address;

    public Customer() {
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }
}
