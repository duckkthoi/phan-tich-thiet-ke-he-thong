<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.ItemDAO" %>
<%@ page import="garaman.model.Item" %>
<%@ page import="garaman.model.Service" %>
<%@ page import="garaman.model.SparePart" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * itemDetail.jsp (Hình 3.4, Bảng 3.5)
     *   outItemDetail: output; subBack: link
     *   ẩn: selectedItemId: Long; selectedItem: Item?; keyword: String
     *   loadItemDetail(itemId): void; backToResults(): void
     * Thuộc tính ẩn được giữ trong phạm vi request của trang.
     */

    private static final String MSG_NOT_FOUND = "Dịch vụ/phụ tùng không còn tồn tại";

    /**
     * Bước 19-26: gọi ItemDAO.getDetail() và lưu selectedItem.
     * Trả về false khi mặt hàng không còn tồn tại (25.1).
     */
    private boolean loadItemDetail(HttpServletRequest request, String itemId) {
        Long selectedItemId;
        try {
            selectedItemId = Long.valueOf(itemId == null ? "" : itemId.trim());
        } catch (NumberFormatException e) {
            showMessage(request, MSG_NOT_FOUND);
            return false;
        }
        request.setAttribute("selectedItemId", selectedItemId);
        try {
            ItemDAO itemDAO = new ItemDAO(DBConnection.getDataSource());
            Optional<Item> selectedItem = itemDAO.getDetail(selectedItemId);
            if (selectedItem.isEmpty()) {
                // 25.1
                showMessage(request, MSG_NOT_FOUND);
                return false;
            }
            request.setAttribute("selectedItem", selectedItem.get());
        } catch (SQLException e) {
            // 7.1
            log("ItemDAO.getDetail() thất bại", e);
            showMessage(request, "Không tải được thông tin, vui lòng thử lại");
        }
        return true;
    }

    /** Bước 28-29: gọi lại trang itemSearch.jsp kèm từ khóa đã nhập. */
    private void backToResults(HttpServletRequest request, HttpServletResponse response, String keyword)
            throws jakarta.servlet.ServletException, java.io.IOException {
        request.getRequestDispatcher("itemSearch.jsp?keyword=" + encode(keyword)).forward(request, response);
    }

    /** showMessage(message): thông báo cho khách hàng. */
    private void showMessage(HttpServletRequest request, String message) {
        request.setAttribute("message", message);
    }
%>
<%
    request.setCharacterEncoding("UTF-8");
    String keyword = request.getParameter("keyword");
    if (keyword == null) keyword = "";
    request.setAttribute("keyword", keyword);

    // Bước 27-28: khách hàng click "Quay lại kết quả" -> backToResults()
    if ("backToResults".equals(request.getParameter("action"))) {
        backToResults(request, response, keyword);
        return;
    }

    // Bước 19: loadItemDetail(itemId); 25.1: không còn tồn tại -> thông báo và backToResults()
    if (!loadItemDetail(request, request.getParameter("itemId"))) {
        backToResults(request, response, keyword);
        return;
    }

    // render()
    Item selectedItem = (Item) request.getAttribute("selectedItem");
    String message = (String) request.getAttribute("message");
    boolean isService = selectedItem instanceof Service;
    String noun = isService ? "dịch vụ" : "phụ tùng";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Chi tiết <%= noun %></title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/view/css/style.css">
    <style>
        .panel { max-width: 560px; }
        .panel p { margin: 8px 0; }
        .actions { display: flex; justify-content: space-between; margin-top: 20px; }
    </style>
</head>
<body>
<div class="panel">
    <% if (selectedItem != null) { %>
    <h2>CHI TIẾT <%= isService ? "DỊCH VỤ" : "PHỤ TÙNG" %></h2>
    <div id="outItemDetail">
        <p><b>Mã <%= noun %>:</b> <%= esc(itemCode(selectedItem)) %></p>
        <p><b>Tên <%= noun %>:</b> <%= esc(selectedItem.getName()) %></p>
        <p><b>Loại:</b> <%= itemType(selectedItem) %></p>
        <p><b>Đơn giá:</b> <%= esc(formatPrice(selectedItem.getPrice())) %></p>
        <% if (isService) { %>
        <p><b>Thời gian thực hiện dự kiến:</b> <%= esc(((Service) selectedItem).getEstimatedDuration()) %> phút</p>
        <% } else { %>
        <p><b>Số lượng còn trong kho:</b> <%= esc(((SparePart) selectedItem).getQuantityInStock()) %></p>
        <% } %>
        <p><b>Mô tả:</b> <%= esc(selectedItem.getDescription()) %></p>
    </div>
    <% } else { %>
    <h2>CHI TIẾT DỊCH VỤ/PHỤ TÙNG</h2>
    <% } %>

    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>

    <div class="actions">
        <a id="subBack" class="btn" href="itemDetail.jsp?action=backToResults&amp;keyword=<%= esc(encode(keyword)) %>">Quay lại kết quả</a>
        <a class="btn" href="customerMain.jsp">Về trang chủ</a>
    </div>
</div>
</body>
</html>
