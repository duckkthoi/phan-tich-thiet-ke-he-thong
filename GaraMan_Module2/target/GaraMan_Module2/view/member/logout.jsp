<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="static garaman.view.ViewHelper.redirectToLogin" %>
<%--
    PHẦN NGOÀI MODULE NHẬN THANH TOÁN (gói view/member): đăng xuất, hủy phiên rồi về trang đăng nhập.
--%>
<%
    session.invalidate();
    redirectToLogin(request, response);
%>
