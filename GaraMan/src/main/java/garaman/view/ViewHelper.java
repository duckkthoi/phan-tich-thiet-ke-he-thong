package garaman.view;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import garaman.model.Customer;
import garaman.model.Item;
import garaman.model.Service;

/**
 * Các hàm hỗ trợ dùng chung cho các trang JSP của gói view: kiểm tra phiên đăng nhập,
 * thoát HTML, mã hóa URL, mã hiển thị và định dạng tiền.
 */
public final class ViewHelper {

    /** Tên thuộc tính phiên giữ khách hàng đã đăng nhập. */
    public static final String LOGGED_IN_CUSTOMER = "loggedInCustomer";

    private static final String LOGIN_PAGE = "/view/member/login.jsp";

    private ViewHelper() {
    }

    // ------------------------------------------------------------------ phiên đăng nhập

    /** Khách hàng đang đăng nhập, hoặc null nếu chưa đăng nhập / phiên đã hết hạn. */
    public static Customer loggedInCustomer(HttpSession session) {
        Object customer = session == null ? null : session.getAttribute(LOGGED_IN_CUSTOMER);
        return customer instanceof Customer c ? c : null;
    }

    /**
     * Kiểm tra đầu trang: nếu khách hàng chưa đăng nhập (hoặc phiên hết hạn) thì chuyển về
     * trang đăng nhập và trả về false để trang dừng xử lý.
     */
    public static boolean requireCustomer(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        if (loggedInCustomer(request.getSession(false)) != null) {
            return true;
        }
        redirectToLogin(request, response);
        return false;
    }

    public static void redirectToLogin(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.sendRedirect(request.getContextPath() + LOGIN_PAGE);
    }

    // ------------------------------------------------------------------ hiển thị

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

    /** Mã hiển thị theo Hình 3.3: DV + id (dịch vụ), PT + id (phụ tùng). */
    public static String itemCode(Item item) {
        return (item instanceof Service ? "DV" : "PT") + String.format("%02d", item.getId());
    }

    public static String itemType(Item item) {
        return item instanceof Service ? "Dịch vụ" : "Phụ tùng";
    }

    /** Số tiền có dấu chấm phân cách hàng nghìn kèm đơn vị, ví dụ 1.520.000 đ. */
    public static String formatPrice(BigDecimal price) {
        if (price == null) {
            return "";
        }
        DecimalFormatSymbols symbols = new DecimalFormatSymbols();
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        return new DecimalFormat("#,##0", symbols).format(price) + " đ";
    }
}
