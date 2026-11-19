package garaman.view;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;

import garaman.model.Item;
import garaman.model.Service;

/**
 * Các hàm hỗ trợ hiển thị dùng chung cho các trang JSP của gói view:
 * thoát HTML, mã hóa URL, mã hiển thị và định dạng tiền.
 */
public final class ViewHelper {

    private ViewHelper() {
    }

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
