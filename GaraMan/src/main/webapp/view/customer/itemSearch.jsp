<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.ItemDAO" %>
<%@ page import="garaman.model.Item" %>
<%@ page import="garaman.model.Service" %>
<%!
    /*
     * itemSearch.jsp (Hình 4.5, Bảng 4.5)
     *   inKeyword: String; subSearch: submit; outItemList: Table
     *   ẩn: keyword: String; items: List<Item>; selectedItemId: Long?; searched: boolean
     *   searchItems(keyword): void; openItemDetail(itemId): void
     * Thuộc tính ẩn được giữ trong phạm vi request của trang.
     */

    /** Bước 6-15: chuẩn hóa, kiểm tra từ khóa rồi gọi ItemDAO.search(). */
    private void searchItems(HttpServletRequest request, String keyword) {
        keyword = keyword == null ? "" : keyword.trim();
        request.setAttribute("keyword", keyword);
        request.setAttribute("searched", false);
        if (keyword.isEmpty()) {
            // 6.1: không gọi ItemDAO
            showMessage(request, "Vui lòng nhập tên dịch vụ/phụ tùng");
            return;
        }
        try {
            ItemDAO itemDAO = new ItemDAO(DBConnection.getDataSource());
            List<Item> items = itemDAO.search(keyword);
            request.setAttribute("items", items);
            request.setAttribute("searched", true);
            if (items.isEmpty()) {
                // 15.1
                showMessage(request, "Không tìm thấy dịch vụ/phụ tùng");
            }
        } catch (SQLException e) {
            // 7.1: lỗi hệ thống, không hiển thị "không tìm thấy"
            log("ItemDAO.search() thất bại", e);
            showMessage(request, "Không tải được thông tin, vui lòng thử lại");
        }
    }

    /** Bước 18-19: ghi nhận selectedItemId và gọi trang itemDetail.jsp kèm từ khóa hiện tại. */
    private void openItemDetail(HttpServletRequest request, HttpServletResponse response, String itemId)
            throws java.io.IOException {
        request.setAttribute("selectedItemId", itemId);
        String keyword = request.getParameter("keyword");
        response.sendRedirect("itemDetail.jsp?itemId=" + encode(itemId)
                + "&keyword=" + encode(keyword == null ? "" : keyword));
    }

    /** showMessage(message): thông báo cho khách hàng. */
    private void showMessage(HttpServletRequest request, String message) {
        request.setAttribute("message", message);
    }

    private static String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }

    private static String esc(Object value) {
        if (value == null) return "";
        String s = value.toString();
        StringBuilder sb = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            switch (c) {
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '&': sb.append("&amp;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }

    /** Mã hiển thị theo Hình 4.4: DV + id (dịch vụ), PT + id (phụ tùng). */
    private static String itemCode(Item item) {
        return (item instanceof Service ? "DV" : "PT") + String.format("%02d", item.getId());
    }

    private static String itemType(Item item) {
        return item instanceof Service ? "Dịch vụ" : "Phụ tùng";
    }

    private static String formatPrice(BigDecimal price) {
        if (price == null) return "";
        DecimalFormatSymbols symbols = new DecimalFormatSymbols();
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        return new DecimalFormat("#,##0", symbols).format(price) + " đ";
    }
%>
<%
    request.setCharacterEncoding("UTF-8");

    // Bước 17-18: khách hàng chọn một dịch vụ/phụ tùng -> openItemDetail(itemId)
    if ("openItemDetail".equals(request.getParameter("action"))) {
        openItemDetail(request, response, request.getParameter("itemId"));
        return;
    }

    // Bước 5-6: submit gọi chính trang này; bước 29-30: quay lại với từ khóa cũ
    String keywordParam = request.getParameter("keyword");
    if (keywordParam != null && (request.getParameter("subSearch") != null || !keywordParam.isBlank())) {
        searchItems(request, keywordParam);
    }

    // render()
    String keyword = (String) request.getAttribute("keyword");
    if (keyword == null) keyword = keywordParam == null ? "" : keywordParam.trim();
    @SuppressWarnings("unchecked")
    List<Item> items = (List<Item>) request.getAttribute("items");
    boolean searched = Boolean.TRUE.equals(request.getAttribute("searched"));
    String message = (String) request.getAttribute("message");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Tìm kiếm dịch vụ và phụ tùng</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 640px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .search-row { display: flex; align-items: center; gap: 8px; }
        .search-row input { flex: 1; padding: 4px 6px; font-size: 14px; }
        .btn { display: inline-block; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; }
        h3 { font-size: 14px; margin: 16px 0 6px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #333; padding: 3px 6px; text-align: left; vertical-align: top; }
        .message { margin: 12px 0; padding: 6px 10px; border: 1px solid #c9a227; background: #fff8dc; }
    </style>
</head>
<body>
<div class="panel">
    <h2>TÌM KIẾM DỊCH VỤ VÀ PHỤ TÙNG</h2>

    <form method="get" action="itemSearch.jsp" class="search-row">
        <label for="inKeyword">Tên hoặc từ khóa:</label>
        <input type="text" id="inKeyword" name="keyword" value="<%= esc(keyword) %>">
        <button type="submit" id="subSearch" name="subSearch" value="1" class="btn">Tìm kiếm</button>
    </form>

    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>

    <% if (searched && items != null && !items.isEmpty()) { %>
    <h3>Kết quả tìm kiếm</h3>
    <table id="outItemList">
        <thead>
        <tr><th>Mã</th><th>Tên dịch vụ/phụ tùng</th><th>Loại</th><th>Đơn giá</th><th>Thao tác</th></tr>
        </thead>
        <tbody>
        <% for (Item item : items) { %>
        <tr>
            <td><%= esc(itemCode(item)) %></td>
            <td><%= esc(item.getName()) %></td>
            <td><%= esc(itemType(item)) %></td>
            <td><%= esc(formatPrice(item.getPrice())) %></td>
            <td><a href="itemSearch.jsp?action=openItemDetail&amp;itemId=<%= item.getId() %>&amp;keyword=<%= esc(encode(keyword)) %>">Xem chi tiết</a></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <p>Tìm thấy <%= items.size() %> kết quả phù hợp.</p>
    <% } %>

    <a class="btn" href="customerMain.jsp">Về trang chủ</a>
</div>
</body>
</html>
