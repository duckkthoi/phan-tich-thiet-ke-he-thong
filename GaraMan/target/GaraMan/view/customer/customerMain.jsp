<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="garaman.model.Customer" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * customerMain.jsp (Hình 3.4, Bảng 3.5)
     *   subSearchMenu: link; ẩn: loggedInCustomer: Customer
     *   openItemSearch(): void  -> kiểm tra phiên đăng nhập của khách hàng rồi gọi trang itemSearch.jsp
     */
    private void openItemSearch(HttpServletRequest request, HttpServletResponse response)
            throws java.io.IOException {
        if (!requireCustomer(request, response)) {
            return;
        }
        response.sendRedirect("itemSearch.jsp");
    }
%>
<%
    // Bước 1-3: khách hàng click subSearchMenu -> trang gọi openItemSearch() của chính nó
    if ("openItemSearch".equals(request.getParameter("action"))) {
        openItemSearch(request, response);
        return;
    }
    Customer customer = loggedInCustomer(session);
    if (customer == null) {
        redirectToLogin(request, response);
        return;
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Trang chủ</title>
    <link rel="stylesheet" href="<%= ctx %>/view/css/style.css">
    <style>
        .panel { max-width: 360px; }
        .btn { margin: 6px 0; }
        .btn[disabled] { cursor: default; }
    </style>
</head>
<body>
<div class="panel">
    <h2>GARAMAN — TRANG CHỦ</h2>
    <p><b>Khách hàng:</b> <%= esc(customer.getFullName()) %></p>
    <a id="subSearchMenu" class="btn" href="<%= ctx %>/view/customer/customerMain.jsp?action=openItemSearch">Tìm dịch vụ/phụ tùng</a><br>
    <%-- "Đặt lịch hẹn" thuộc module khác (appointment.jsp), chưa nằm trong phạm vi module này --%>
    <button class="btn" type="button" disabled>Đặt lịch hẹn</button><br>
    <a class="btn" href="<%= ctx %>/view/member/logout.jsp">Đăng xuất</a>
</div>
</body>
</html>
