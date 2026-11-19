<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.BusinessException" %>
<%@ page import="garaman.dao.InvoiceDetailDAO" %>
<%@ page import="garaman.dao.ItemDAO" %>
<%@ page import="garaman.model.Item" %>
<%@ page import="garaman.model.SparePart" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * addItem.jsp (Hình 3.5, Hình 3.6, Bảng 3.6)
     *   inItemName; subSearch; outItemList; inQuantity; subAddButton
     *   ẩn: invoiceId, keyword, items, selectedItemId, quantity
     *   searchItems(keyword); addItem(itemId, quantity); backToInvoice()
     * Thuộc tính ẩn được giữ trong phạm vi request của trang.
     */

    private static final String MSG_ERROR = "Không thực hiện được thao tác, vui lòng thử lại";

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
            showMessage(request, MSG_ERROR);
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
        Integer qty = parseQuantity(quantity);
        if (qty == null) {
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
            showMessage(request, MSG_ERROR);
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

    /** Số lượng phải là số nguyên lớn hơn 0; trả về null nếu không hợp lệ. */
    private static Integer parseQuantity(String value) {
        try {
            int qty = Integer.parseInt(value == null ? "" : value.trim());
            return qty >= 1 ? qty : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    if (!requireSalesStaff(request, response)) return;

    Long invoiceId = parseId(request.getParameter("invoiceId"));
    request.setAttribute("invoiceId", invoiceId);
    String action = request.getParameter("action");

    if ("backToInvoice".equals(action)) {
        backToInvoice(request, response);
        return;
    }

    boolean searchClicked = request.getParameter("subSearch") != null;
    // Bấm Tìm kiếm thì bỏ mặt hàng đang chọn
    Long selectedItemId = searchClicked ? null : parseId(request.getParameter("selectedItemId"));
    request.setAttribute("selectedItemId", selectedItemId);
    String quantity = request.getParameter("quantity");
    request.setAttribute("quantity", quantity);

    // Bước 48-49: submit gọi chính trang này -> searchItems(keyword); chọn mặt hàng giữ lại từ khóa
    String keywordParam = request.getParameter("keyword");
    if (keywordParam != null && (searchClicked || !keywordParam.isBlank())) {
        searchItems(request, keywordParam);
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "addItem".equals(action)) {
        // Bước 57-58: chọn mặt hàng, nhập số lượng, click Thêm -> addItem(itemId, quantity)
        addItem(request, response, selectedItemId, quantity);
        if (redirected(response)) return;
    }

    // render()
    String keyword = (String) request.getAttribute("keyword");
    if (keyword == null) keyword = keywordParam == null ? "" : keywordParam.trim();
    @SuppressWarnings("unchecked")
    List<Item> items = (List<Item>) request.getAttribute("items");
    Item selectedItem = items == null || selectedItemId == null ? null
            : items.stream().filter(item -> selectedItemId.equals(item.getId())).findFirst().orElse(null);
    String message = (String) request.getAttribute("message");
    String invoiceIdText = idOrEmpty(invoiceId);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Bổ sung dịch vụ và phụ tùng</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/view/css/style.css">
    <style>
        .panel { max-width: 560px; }
        .panel p { margin: 8px 0; }
        .qty-row input { width: 80px; padding: 4px 6px; font-size: 14px; }
        .btn { margin: 8px 0; font-family: inherit; }
        table { margin-top: 6px; }
    </style>
</head>
<body>
<div class="panel">
    <h2>BỔ SUNG DỊCH VỤ VÀ PHỤ TÙNG</h2>
    <p><b>Hóa đơn:</b> <%= esc(invoiceCode(invoiceId)) %></p>

    <form method="get" action="addItem.jsp">
        <input type="hidden" name="invoiceId" value="<%= invoiceIdText %>">
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
            <td><a href="addItem.jsp?invoiceId=<%= invoiceIdText %>&amp;keyword=<%= esc(encode(keyword)) %>&amp;selectedItemId=<%= item.getId() %>">Chọn</a></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    <% } %>

    <% if (selectedItem != null) { %>
    <form method="post" action="addItem.jsp">
        <input type="hidden" name="action" value="addItem">
        <input type="hidden" name="invoiceId" value="<%= invoiceIdText %>">
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

    <a class="btn" href="addItem.jsp?action=backToInvoice&amp;invoiceId=<%= invoiceIdText %>">Quay lại</a>
</div>
</body>
</html>
