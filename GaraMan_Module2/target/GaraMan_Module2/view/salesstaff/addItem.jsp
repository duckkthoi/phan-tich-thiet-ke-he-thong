<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.BusinessException" %>
<%@ page import="garaman.dao.InvoiceDetailDAO" %>
<%@ page import="garaman.dao.ItemDAO" %>
<%@ page import="garaman.model.Item" %>
<%@ page import="garaman.model.SalesStaff" %>
<%@ page import="garaman.model.Service" %>
<%@ page import="garaman.model.SparePart" %>
<%!
    /*
     * addItem.jsp (Hình 4.6, Hình 4.7, Bảng 4.6)
     *   inItemName; subSearch; outItemList; inQuantity; subAddButton
     *   ẩn: invoiceId, keyword, items, selectedItemId, quantity
     *   searchItems(keyword); addItem(itemId, quantity); backToInvoice()
     * Thuộc tính ẩn được giữ trong phạm vi request của trang.
     */

    /** Bước 49-56: gọi ItemDAO.search() (dùng lại phương thức của module tìm kiếm). */
    private void searchItems(HttpServletRequest request, String keyword) {
        keyword = keyword == null ? "" : keyword.trim();
        request.setAttribute("keyword", keyword);
        if (keyword.isEmpty()) {
            showMessage(request, "Vui lòng nhập tên dịch vụ/phụ tùng");
            return;
        }
        try {
            ItemDAO itemDAO = new ItemDAO(DBConnection.getDataSource());
            List<Item> items = itemDAO.search(keyword);
            request.setAttribute("items", items);
            if (items.isEmpty()) {
                // 55.1
                showMessage(request, "Không tìm thấy phụ tùng/dịch vụ");
            }
        } catch (SQLException e) {
            // 7.1
            log("ItemDAO.search() thất bại", e);
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
    }

    /**
     * Bước 58-65: kiểm tra số lượng là số nguyên dương rồi gọi InvoiceDetailDAO.addDetail().
     * 58.1: số lượng không hợp lệ → không gọi DAO. 60.2: BusinessException → hiển thị lỗi.
     * Thành công → gọi lại invoiceDetail.jsp (loadInvoice(invoiceId)).
     */
    private void addItem(HttpServletRequest request, HttpServletResponse response, Long itemId, String quantity)
            throws java.io.IOException {
        Long invoiceId = (Long) request.getAttribute("invoiceId");
        Integer qty;
        try {
            qty = Integer.valueOf(quantity == null ? "" : quantity.trim());
        } catch (NumberFormatException e) {
            qty = null;
        }
        if (qty == null || qty < 1) {
            // 58.1
            showMessage(request, "Số lượng không hợp lệ");
            return;
        }
        if (itemId == null) {
            showMessage(request, "Dịch vụ/phụ tùng không còn tồn tại");
            return;
        }
        try {
            InvoiceDetailDAO invoiceDetailDAO = new InvoiceDetailDAO(DBConnection.getDataSource());
            invoiceDetailDAO.addDetail(invoiceId, itemId, qty);
            response.sendRedirect("invoiceDetail.jsp?invoiceId=" + invoiceId);
        } catch (BusinessException e) {
            // 60.2
            showMessage(request, e.getMessage());
        } catch (SQLException e) {
            // 7.1
            log("InvoiceDetailDAO.addDetail() thất bại", e);
            showMessage(request, "Không thực hiện được thao tác, vui lòng thử lại");
        }
    }

    /** 78.2 / nút Quay lại: đưa về trang invoiceDetail.jsp của hóa đơn đang bổ sung. */
    private void backToInvoice(HttpServletRequest request, HttpServletResponse response) throws java.io.IOException {
        response.sendRedirect("invoiceDetail.jsp?invoiceId=" + request.getAttribute("invoiceId"));
    }

    /** showMessage(message): thông báo cho nhân viên. */
    private void showMessage(HttpServletRequest request, String message) {
        request.setAttribute("message", message);
    }

    private static SalesStaff loggedInStaff(HttpSession session) {
        Object staff = session == null ? null : session.getAttribute("loggedInStaff");
        if (staff instanceof SalesStaff && SalesStaff.POSITION.equals(((SalesStaff) staff).getPosition())) {
            return (SalesStaff) staff;
        }
        return null;
    }

    private static Long parseId(String value) {
        try {
            return value == null ? null : Long.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
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

    /** Mã hiển thị theo Hình 4.6. */
    private static String invoiceCode(Long id) {
        return id == null ? "" : "HD" + String.format("%03d", id);
    }

    private static String itemCode(Item item) {
        return (item instanceof Service ? "DV" : "PT") + String.format("%02d", item.getId());
    }

    private static String formatMoney(BigDecimal amount) {
        if (amount == null) return "";
        DecimalFormatSymbols symbols = new DecimalFormatSymbols();
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        return new DecimalFormat("#,##0", symbols).format(amount);
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    if (loggedInStaff(session) == null) {
        response.sendRedirect(request.getContextPath() + "/view/member/login.jsp");
        return;
    }
    Long invoiceId = parseId(request.getParameter("invoiceId"));
    request.setAttribute("invoiceId", invoiceId);
    String action = request.getParameter("action");

    if ("backToInvoice".equals(action)) {
        backToInvoice(request, response);
        return;
    }

    Long selectedItemId = parseId(request.getParameter("selectedItemId"));
    request.setAttribute("selectedItemId", selectedItemId);
    String quantity = request.getParameter("quantity");
    request.setAttribute("quantity", quantity);

    // Bước 48-49: submit gọi chính trang này -> searchItems(keyword); chọn mặt hàng giữ lại từ khóa
    String keywordParam = request.getParameter("keyword");
    if (keywordParam != null && (request.getParameter("subSearch") != null || !keywordParam.isBlank())) {
        searchItems(request, keywordParam);
    }
    if (request.getParameter("subSearch") != null) {
        selectedItemId = null;
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "addItem".equals(action)) {
        // Bước 57-58: chọn mặt hàng, nhập số lượng, click Thêm -> addItem(itemId, quantity)
        addItem(request, response, selectedItemId, quantity);
        if (response.containsHeader("Location")) return;
    }

    // render()
    String keyword = (String) request.getAttribute("keyword");
    if (keyword == null) keyword = keywordParam == null ? "" : keywordParam.trim();
    @SuppressWarnings("unchecked")
    List<Item> items = (List<Item>) request.getAttribute("items");
    Item selectedItem = null;
    if (items != null && selectedItemId != null) {
        for (Item item : items) {
            if (selectedItemId.equals(item.getId())) {
                selectedItem = item;
                break;
            }
        }
    }
    String message = (String) request.getAttribute("message");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Bổ sung dịch vụ và phụ tùng</title>
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 560px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        .panel p { margin: 8px 0; }
        .search-row { display: flex; align-items: center; gap: 8px; }
        .search-row input { flex: 1; padding: 4px 6px; font-size: 14px; }
        .qty-row input { width: 80px; padding: 4px 6px; font-size: 14px; }
        .btn { display: inline-block; margin: 8px 0; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; font-family: inherit; }
        table { border-collapse: collapse; width: 100%; margin-top: 6px; }
        th, td { border: 1px solid #333; padding: 3px 6px; text-align: left; vertical-align: top; }
        form { margin: 0; }
        .message { margin: 12px 0; padding: 6px 10px; border: 1px solid #c9a227; background: #fff8dc; }
    </style>
</head>
<body>
<div class="panel">
    <h2>BỔ SUNG DỊCH VỤ VÀ PHỤ TÙNG</h2>
    <p><b>Hóa đơn:</b> <%= esc(invoiceCode(invoiceId)) %></p>

    <form method="get" action="addItem.jsp">
        <input type="hidden" name="invoiceId" value="<%= invoiceId == null ? "" : invoiceId %>">
        <div class="search-row">
            <label for="inItemName">Tên mặt hàng:</label>
            <input type="text" id="inItemName" name="keyword" value="<%= esc(keyword) %>">
        </div>
        <button type="submit" id="subSearch" name="subSearch" value="1" class="btn">Tìm kiếm</button>
    </form>

    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>

    <% if (items != null && !items.isEmpty()) { %>
    <table id="outItemList">
        <thead>
        <tr><th>Mã</th><th>Tên phụ tùng</th><th>Đơn giá</th><th>Chọn</th></tr>
        </thead>
        <tbody>
        <% for (Item item : items) { %>
        <tr>
            <td><%= esc(itemCode(item)) %></td>
            <td><%= esc(item.getName()) %></td>
            <td><%= esc(formatMoney(item.getPrice())) %></td>
            <td><a href="addItem.jsp?invoiceId=<%= invoiceId == null ? "" : invoiceId %>&amp;keyword=<%= esc(encode(keyword)) %>&amp;selectedItemId=<%= item.getId() %>">Chọn</a></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <% } %>

    <% if (selectedItem != null) { %>
    <form method="post" action="addItem.jsp">
        <input type="hidden" name="action" value="addItem">
        <input type="hidden" name="invoiceId" value="<%= invoiceId == null ? "" : invoiceId %>">
        <input type="hidden" name="keyword" value="<%= esc(keyword) %>">
        <input type="hidden" name="selectedItemId" value="<%= selectedItem.getId() %>">
        <p><b>Đã chọn:</b> <%= esc(selectedItem.getName()) %></p>
        <% if (selectedItem instanceof SparePart) { %>
        <p><b>Tồn kho:</b> <%= ((SparePart) selectedItem).getQuantityInStock() %></p>
        <% } %>
        <p class="qty-row">
            <label for="inQuantity">Số lượng:</label>
            <input type="text" id="inQuantity" name="quantity" value="<%= esc(quantity == null ? "1" : quantity) %>">
        </p>
        <button type="submit" id="subAddButton" class="btn">Thêm vào hóa đơn</button>
    </form>
    <% } %>

    <a class="btn" href="addItem.jsp?action=backToInvoice&amp;invoiceId=<%= invoiceId == null ? "" : invoiceId %>">Quay lại</a>
</div>
</body>
</html>
