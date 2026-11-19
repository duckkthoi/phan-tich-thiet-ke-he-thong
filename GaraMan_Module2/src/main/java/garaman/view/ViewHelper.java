package garaman.view;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import garaman.model.Invoice;
import garaman.model.Item;
import garaman.model.SalesStaff;
import garaman.model.Service;

/**
 * Các hàm hỗ trợ dùng chung cho các trang JSP của gói view: kiểm tra phiên đăng nhập,
 * đọc tham số, thoát HTML, mã hiển thị và định dạng ngày, tiền.
 */
public final class ViewHelper {

    /** Tên thuộc tính phiên giữ nhân viên bán hàng đã đăng nhập. */
    public static final String LOGGED_IN_STAFF = "loggedInStaff";

    private static final String LOGIN_PAGE = "/view/member/login.jsp";
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private ViewHelper() {
    }

    // ------------------------------------------------------------------ phiên đăng nhập

    /** Nhân viên bán hàng đang đăng nhập, hoặc null nếu chưa đăng nhập / không có quyền SalesStaff. */
    public static SalesStaff loggedInStaff(HttpSession session) {
        Object staff = session == null ? null : session.getAttribute(LOGGED_IN_STAFF);
        if (staff instanceof SalesStaff salesStaff && SalesStaff.POSITION.equals(salesStaff.getPosition())) {
            return salesStaff;
        }
        return null;
    }

    /**
     * Kiểm tra đầu trang: nếu chưa đăng nhập (hoặc phiên hết hạn) thì chuyển về trang đăng nhập
     * và trả về false để trang dừng xử lý.
     */
    public static boolean requireSalesStaff(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (loggedInStaff(request.getSession(false)) != null) {
            return true;
        }
        redirectToLogin(request, response);
        return false;
    }

    public static void redirectToLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.sendRedirect(request.getContextPath() + LOGIN_PAGE);
    }

    /** true nếu phương thức xử lý vừa gọi đã chuyển hướng sang trang khác. */
    public static boolean redirected(HttpServletResponse response) {
        return response.containsHeader("Location");
    }

    // ------------------------------------------------------------------ tham số

    /** Đọc mã (id) từ tham số; null nếu thiếu hoặc không phải số. */
    public static Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** In id ra thuộc tính HTML/URL, rỗng nếu null. */
    public static String idOrEmpty(Long id) {
        return id == null ? "" : id.toString();
    }

    // ------------------------------------------------------------------ HTML, URL

    /** Thoát các kí tự đặc biệt của HTML để in dữ liệu ra trang an toàn. */
    public static String esc(Object value) {
        if (value == null) {
            return "";
        }
        String s = value.toString();
        StringBuilder sb = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<' -> sb.append("&lt;");
                case '>' -> sb.append("&gt;");
                case '&' -> sb.append("&amp;");
                case '"' -> sb.append("&quot;");
                case '\'' -> sb.append("&#39;");
                default -> sb.append(c);
            }
        }
        return sb.toString();
    }

    /** Mã hóa giá trị để ghép vào tham số URL. */
    public static String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    // ------------------------------------------------------------------ mã hiển thị (Hình 3.5)

    public static String customerCode(Long id) {
        return id == null ? "" : "KH" + String.format("%02d", id);
    }

    public static String invoiceCode(Long id) {
        return id == null ? "" : "HD" + String.format("%03d", id);
    }

    public static String itemCode(Item item) {
        return (item instanceof Service ? "DV" : "PT") + String.format("%02d", item.getId());
    }

    public static String itemType(Item item) {
        return item instanceof Service ? "Dịch vụ" : "Phụ tùng";
    }

    /** Nhãn hiển thị của trạng thái hóa đơn (Bảng 3.7). */
    public static String statusLabel(String status) {
        if (Invoice.DRAFT.equals(status)) return "Chưa chốt";
        if (Invoice.CONFIRMED.equals(status)) return "Đã chốt, chưa thanh toán";
        if (Invoice.PAID.equals(status)) return "Đã thanh toán";
        return status;
    }

    // ------------------------------------------------------------------ định dạng

    public static String formatDate(LocalDateTime dateTime) {
        return dateTime == null ? "" : dateTime.format(DATE_FORMAT);
    }

    /** Số tiền có dấu chấm phân cách hàng nghìn, ví dụ 1.520.000 (đơn vị "đ" do trang in kèm). */
    public static String formatMoney(BigDecimal amount) {
        if (amount == null) {
            return "";
        }
        DecimalFormatSymbols symbols = new DecimalFormatSymbols();
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        return new DecimalFormat("#,##0", symbols).format(amount);
    }
}
