<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.MemberDAO" %>
<%@ page import="garaman.model.Customer" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%--
    PHẦN NGOÀI MODULE TÌM KIẾM (gói view/member, Hình 3.12).
    Đăng nhập của khách hàng (thành viên) để tạo phiên loggedInCustomer
    (tiền điều kiện của kịch bản: khách hàng đã đăng nhập).
--%>
<%
    request.setCharacterEncoding("UTF-8");
    final String MSG_WRONG = "Sai tên đăng nhập hoặc mật khẩu";
    String message = null;
    String username = request.getParameter("username");
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String password = request.getParameter("password");
        if (username == null || username.isBlank() || password == null || password.isEmpty()) {
            message = MSG_WRONG;
        } else {
            try {
                Optional<Customer> customer = new MemberDAO(DBConnection.getDataSource())
                        .checkCustomerLogin(username.trim(), password);
                if (customer.isPresent()) {
                    // Hủy phiên cũ, tạo phiên mới để tránh dùng lại mã phiên trước khi đăng nhập
                    session.invalidate();
                    request.getSession(true).setAttribute(LOGGED_IN_CUSTOMER, customer.get());
                    response.sendRedirect(request.getContextPath() + "/view/customer/customerMain.jsp");
                    return;
                }
                message = MSG_WRONG;
            } catch (SQLException e) {
                log("MemberDAO.checkCustomerLogin() thất bại", e);
                message = "Không thực hiện được thao tác, vui lòng thử lại";
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GaraMan - Đăng nhập</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/view/css/style.css">
    <style>
        .panel { max-width: 360px; }
        label { display: block; margin: 8px 0 4px; }
        input[type=text], input[type=password] { width: 100%; box-sizing: border-box; padding: 4px 6px; font-size: 14px; }
        .btn { margin-top: 12px; }
    </style>
</head>
<body>
<div class="panel">
    <h2>ĐĂNG NHẬP</h2>
    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>
    <form method="post" action="login.jsp">
        <label for="inUsername">Tên đăng nhập (số điện thoại):</label>
        <input type="text" id="inUsername" name="username" value="<%= esc(username) %>">
        <label for="inPassword">Mật khẩu:</label>
        <input type="password" id="inPassword" name="password">
        <button type="submit" class="btn">Đăng nhập</button>
    </form>
</div>
</body>
</html>
