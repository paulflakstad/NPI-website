<%-- 
    Document   : navigate
    Created on : Nov 19, 2012, 4:30:06 PM
    Author     : flakstad
--%><%@ page import="no.npolar.util.CmsAgent" 
%><%
CmsAgent cms = new CmsAgent(pageContext, request, response);
// Get the navigation target (set as a parameter value)
String navTarget = request.getParameter("navtarget");
String redirAbsPath = null;

if (navTarget == null) {
    throw new NullPointerException("No navigation target supplied.");
}
// Navigation target is non-empty, redirect back
if (navTarget.isEmpty()) {
    try {
        navTarget = request.getParameter("ref") != null ? request.getParameter("ref") : "/";
    } catch (Exception e) {
        throw new IllegalArgumentException("Something went terribly wrong during navigation.");
    }
}
else if (!navTarget.startsWith("/")) {
    throw new IllegalArgumentException("Navigation target did not point to a local resource.");
}

// All should be OK. Redirect.
redirAbsPath = request.getScheme() + "://" + request.getServerName() + navTarget;
//CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
%>