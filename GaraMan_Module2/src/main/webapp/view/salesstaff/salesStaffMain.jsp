<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="garaman.model.SalesStaff" %>
<%@ page import="static garaman.view.ViewHelper.*" %>
<%!
    /*
     * salesStaffMain.jsp (Hình 3.5, Hình 3.6, Bảng 3.6)
     *   subPaymentMenu: link; ẩn: loggedInStaff: SalesStaff
     *   openPayment(): void -> kiểm tra phiên và quyền SalesStaff, mở trang tìm khách hàng
     */

    /** Bước 2-3: kiểm tra phiên đăng nhập và quyền SalesStaff của loggedInStaff rồi gọi customerSearch.jsp. */
    private void openPayment(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws java.io.IOException {
        if (!requireSalesStaff(request, response)) {
            return;
        }
        // Mở phiên tìm kiếm mới: xóa thuộc tính ẩn của lần tìm trước (customerSearch.*)
        for (String name : java.util.Collections.list(session.getAttributeNames())) {
            if (name.startsWith("customerSearch.")) {
                session.removeAttribute(name);
            }
        }
        response.sendRedirect(request.getContextPath() + "/view/salesstaff/customerSearch.jsp");
    }
%>
<%
    // Bước 1-2: nhân viên click subPaymentMenu -> trang gọi openPayment() của chính nó
    if ("openPayment".equals(request.getParameter("action"))) {
        openPayment(request, response, session);
        return;
    }
    SalesStaff staff = loggedInStaff(session);
    if (staff == null) {
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
    <title>GaraMan - Trang chủ nhân viên</title>
    <link rel="stylesheet" href="<%= ctx %>/view/css/style.css">
    <style>
        .panel { max-width: 360px; }
        .btn { margin: 6px 0; }
    </style>
</head>
<body>
<div class="panel">
    <h2>TRANG CHỦ NHÂN VIÊN</h2>
    <p><b>Nhân viên:</b> <%= esc(staff.getFullName()) %></p>
    <a id="subPaymentMenu" class="btn" href="<%= ctx %>/view/salesstaff/salesStaffMain.jsp?action=openPayment">Thanh toán</a><br>
    <a class="btn" href="<%= ctx %>/view/member/logout.jsp">Đăng xuất</a>
</div>
</body>
</html>
