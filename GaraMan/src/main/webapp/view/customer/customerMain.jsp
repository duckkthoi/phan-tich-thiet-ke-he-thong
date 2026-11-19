<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%!
    /*
     * customerMain.jsp (Hình 3.4, Bảng 3.5)
     *   subSearchMenu: link
     *   openItemSearch(): void  -> gọi trang itemSearch.jsp (không yêu cầu đăng nhập)
     */
    private void openItemSearch(HttpServletResponse response) throws java.io.IOException {
        response.sendRedirect("itemSearch.jsp");
    }
%>
<%
    // Bước 1-3: khách hàng click subSearchMenu -> trang gọi openItemSearch() của chính nó
    if ("openItemSearch".equals(request.getParameter("action"))) {
        openItemSearch(response);
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
    <p>Chào mừng quý khách đến với GaraMan.</p>
    <a id="subSearchMenu" class="btn" href="<%= ctx %>/view/customer/customerMain.jsp?action=openItemSearch">Tìm dịch vụ/phụ tùng</a><br>
    <%-- "Đặt lịch hẹn" thuộc module khác (appointment.jsp), chưa nằm trong phạm vi module này --%>
    <button class="btn" type="button" disabled>Đặt lịch hẹn</button>
</div>
</body>
</html>
