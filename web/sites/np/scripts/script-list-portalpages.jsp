<%-- 
    Document   : script-list-portalpages
    Created on : May 31, 2012, 9:54:53 AM
    Author     : flakstad
--%><%@ page import="no.npolar.util.CmsAgent,
                 java.util.*,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.*,
                 org.opencms.file.types.*,
                 org.opencms.main.*,
                 org.opencms.util.CmsUUID" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "<div style=\"border:1px solid #900; color:#900; font-family:Courier, Monospace; font-size:80%; padding:1em; margin:2em;\">";
    trace+= "<p style=\"font-weight:bold;\">" + e.getMessage() + "</p>";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    trace += "</div>";
    return trace;
}
%><%
// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

// Folder to read files from
final String FOLDER = requestFolderUri;//"/";
// Filter for resource type "person"
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId());

out.println("<h4>Collecting files ...</h4><ul>");

List filesInFolder = cmso.readResources(FOLDER, rf, true);
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    // Get a list of all siblings (includes the resource itself)
    List siblings = cmso.readSiblings(filePath, rf);
    out.println("<li><code>" + filePath + "</code> (plus " + (siblings.size() - 1) + " siblings)</li>");
}
out.println("</ul>");
%>