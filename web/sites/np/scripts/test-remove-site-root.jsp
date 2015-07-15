<%-- 
    Document   : test-remove-site-root
    Created on : 24.mar.2011, 04:32:03
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*,
                org.opencms.file.*,
                org.opencms.file.types.*,
                org.opencms.main.*,
                java.util.*,
                java.io.IOException,
                no.npolar.util.*" 
        contentType="text/html" 
        pageEncoding="UTF-8" 
%><%
CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

String rootPath = "/sites/np/images/dyreliv/NP005985-ismxke-BF.jpg";
String sitePath = cmso.getRequestContext().removeSiteRoot(rootPath);
String mimeType = OpenCms.getResourceManager().getMimeType(sitePath, null);
CmsResource r = cmso.readResource(sitePath);

out.println("Site path: " + OpenCms.getSiteManager().getCurrentSite(cmso).getSiteMatcher().getUrl() + sitePath + "<br />" +
		"Mime type: " + mimeType + "<br />" +
		"Length: " + r.getLength() + "");
%>