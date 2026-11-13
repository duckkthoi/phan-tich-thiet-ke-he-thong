<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Optional" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="garaman.config.DBConnection" %>
<%@ page import="garaman.dao.MemberDAO" %>
<%@ page import="garaman.model.SalesStaff" %>
<%--
    PHẦN NGOÀI MODULE NHẬN THANH TOÁN (gói view/member, Hình 4.13).
    Đăng nhập tối thiểu chỉ để tạo phiên loggedInStaff cho nhân viên bán hàng
    (tiền điều kiện của kịch bản: nhân viên bán hàng đã đăng nhập).
--%>
<%!
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
%>
<%
    request.setCharacterEncoding("UTF-8");
    String message = null;
    String username = request.getParameter("username");
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String password = request.getParameter("password");
        if (username == null || username.isBlank() || password == null || password.isEmpty()) {
            message = "Sai tên đăng nhập hoặc mật khẩu";
        } else {
            try {
                Optional<SalesStaff> staff = new MemberDAO(DBConnection.getDataSource())
                        .checkLogin(username.trim(), password);
                if (staff.isPresent()) {
                    session.invalidate();
                    HttpSession newSession = request.getSession(true);
                    newSession.setAttribute("loggedInStaff", staff.get());
                    response.sendRedirect(request.getContextPath() + "/view/salesstaff/salesStaffMain.jsp");
                    return;
                }
                message = "Sai tên đăng nhập hoặc mật khẩu";
            } catch (SQLException e) {
                log("MemberDAO.checkLogin() thất bại", e);
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
    <style>
        body { font-family: Arial, Helvetica, sans-serif; font-size: 14px; margin: 24px; color: #222; }
        .panel { border: 1px solid #555; border-radius: 4px; max-width: 360px; padding: 0 16px 16px; }
        .panel h2 { font-size: 15px; text-align: center; margin: 0 -16px 12px; padding: 10px 16px; border-bottom: 1px solid #555; }
        label { display: block; margin: 8px 0 4px; }
        input[type=text], input[type=password] { width: 100%; box-sizing: border-box; padding: 4px 6px; font-size: 14px; }
        .btn { display: inline-block; margin-top: 12px; padding: 4px 12px; border: 1px solid #5b8fb9; background: #cfe5f7;
               color: #000; text-decoration: none; font-size: 14px; cursor: pointer; }
        .message { margin: 12px 0; padding: 6px 10px; border: 1px solid #c9a227; background: #fff8dc; }
    </style>
</head>
<body>
<div class="panel">
    <h2>ĐĂNG NHẬP</h2>
    <% if (message != null) { %>
    <div class="message"><%= esc(message) %></div>
    <% } %>
    <form method="post" action="login.jsp">
        <label for="inUsername">Tên đăng nhập:</label>
        <input type="text" id="inUsername" name="username" value="<%= esc(username) %>">
        <label for="inPassword">Mật khẩu:</label>
        <input type="password" id="inPassword" name="password">
        <button type="submit" class="btn">Đăng nhập</button>
    </form>
</div>
</body>
</html>
