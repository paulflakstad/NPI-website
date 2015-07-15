<%-- 
    Document   : script-create-files-batch
    Created on : Aug 23, 2012, 12:49:15 PM
    Author     : flakstad
--%><%@page import="org.opencms.lock.CmsLock"%>
<%@page import="org.opencms.util.CmsStringUtil"%>
<%@ page import="no.npolar.util.CmsAgent,
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
// Action element, CmsObject, "current" file's URI and its folder URI
CmsAgent cms            = new CmsAgent(pageContext, request, response);
CmsObject cmso          = cms.getCmsObject();
String requestFileUri   = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();



/////////////////////////////////////////////////////////////////////////////////////////
//                          EDIT THIS PART IF NECESSARY
/////////////////////////////////////////////////////////////////////////////////////////

// The file type to create (default is "resourceinfo")
final String CREATE_FILETYPE        = "resourceinfo";

// The file extension to add to the created files (default is ".html")
final String CREATE_FILE_EXT        = ".html";

// Folder to process (defaults to requestFileUri, which is the "current" folder)
final String BASE_FOLDER            = requestFolderUri;

// The file type to create a new file for (default is "binary")
final String BASE_FILETYPE          = "binary";

// Files with these extensions will be collected and processed (add/remove according to needs)
final List<String> BASE_FILE_EXT    = Arrays.asList(new String[] { 
                                                            "pdf"
                                                            , "ppt"
                                                            , "pptx"
                                                            , "doc"
                                                            , "docx"
                                                            });
/////////////////////////////////////////////////////////////////////////////////////////
//                          DO NOT EDIT ANYTHING BELOW THIS
/////////////////////////////////////////////////////////////////////////////////////////








CmsLock folderLock = cmso.getLock(cmso.readResource(BASE_FOLDER));
if (!(folderLock.isNullLock() || folderLock.isOwnedBy(cmso.getRequestContext().currentUser())))
    throw new ServletException("The folder '" + BASE_FOLDER + "' is locked by a different user");

CmsResourceFilter filter = CmsResourceFilter.DEFAULT_FILES;
filter.requireType(OpenCms.getResourceManager().getResourceType(BASE_FILETYPE).getTypeId()).addRequireFile();

List<CmsResource> filesInFolder = cmso.readResources(BASE_FOLDER, filter, false);
if (filesInFolder.contains(cmso.readResource(requestFileUri))) {
    filesInFolder.remove(cmso.readResource(requestFileUri));
}
if (!filesInFolder.isEmpty()) {
    Iterator<CmsResource> iFiles = filesInFolder.iterator();
    out.println("<h4>Creating files in folder '" + BASE_FOLDER + "' ...</h4><ul>");
    while (iFiles.hasNext()) {
        CmsResource res = iFiles.next();
        String resName = res.getName();
        String newResName = resName;
        if (resName.lastIndexOf(".") != -1) {
            String resExt = resName.substring(resName.lastIndexOf(".") + 1);
            if (!BASE_FILE_EXT.contains(resExt)) {
                out.println("<!-- extension '" + resExt + "' found (" + resName + "), skipping -->");
                continue;
            }
            newResName = resName.substring(0, resName.lastIndexOf("."));
        }
        try {
            String newResPath = BASE_FOLDER.concat(newResName).concat(CREATE_FILE_EXT);
            if (!cmso.existsResource(newResPath)) {
                cmso.createResource(newResPath, OpenCms.getResourceManager().getResourceType("resourceinfo").getTypeId());
                out.println("<li>" + newResName + CREATE_FILE_EXT + " created</li>");
            }
            else {
                out.println("<li>Skipped <a href=\"" + cms.link(newResPath) + "\">" + newResName + CREATE_FILE_EXT + "</a> <em>(file existed)</em></li>");
            }
            
        } catch (Exception e) {
            out.println("<h4>Unable to batch create resourceinfo files in folder '" + BASE_FOLDER + "': " + e.getMessage());
            out.println("<div style=\"background:fcc; color:#333; border:1px solid 900; padding:1em;\">" + getStackTrace(e) + "</div>");
        }
    }
    out.println("</ul>");
}

%>