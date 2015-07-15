<%-- 
    Document   : lookup-employee
    Created on : 26.apr.2011, 10:53:22
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 org.opencms.file.CmsObject"  session="true" 
%><%
final CmsAgent cms = new CmsAgent(pageContext, request, response);
final CmsObject cmso = cms.getCmsObject();

String requestedEmployeeUri = request.getParameter("employeeuri");

if (requestedEmployeeUri != null && cmso.existsResource(requestedEmployeeUri)) {
    response.sendRedirect(requestedEmployeeUri);
}
%>