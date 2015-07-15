<%-- 
    Document   : script-move-resources
    Created on : 24.feb.2011, 20:15:36
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
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

// Folders to read files from
final String FOLDER_NO = "/no/ansatte/";
final String FOLDER_EN = "/en/people/";
// Filter for resource type "person"
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType("person").getTypeId());

List filesInFolder = cmso.getFilesInFolder(FOLDER_NO, rf);
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file name
    String fileName = fileResource.getName();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    // Get a list of all siblings (includes the resource itself)
    List siblings = cmso.readSiblings(filePath, rf);
    out.println("Collected file <code>" + filePath + " (" + fileName + ")</code> plus " + (siblings.size() - 1) + " siblings<br />");
    
    // Folder to create
    String newFolderName = fileName.substring(0, fileName.indexOf(".html"));
    
    try {
        // Create a folder with the same name as the file (but without the .html suffix)
        CmsResource createdFolder = cmso.createResource(FOLDER_NO.concat(newFolderName), CmsResourceTypeFolder.RESOURCE_TYPE_ID);
        out.println("Created folder <code>" + cmso.getSitePath(createdFolder) + "</code><br />");
        
        cmso.lockResource(filePath);
        String newFilePath = cmso.getSitePath(createdFolder).concat("index.html");
        // Move the file from its current location into the newly created folder, making it the folder's index file
        cmso.moveResource(filePath, newFilePath);
        cmso.unlockResource(cmso.getSitePath(createdFolder));
        out.println("Successfully moved <code>" + filePath + "</code> to <code>" + newFilePath + "</code><br />");
        
        // Handle siblings
        Iterator iSiblings = siblings.iterator();
        while (iSiblings.hasNext()) {
            CmsResource sibling = (CmsResource)iSiblings.next();
            String siblingPath = cmso.getSitePath(sibling);
            if (siblingPath.startsWith("/en/")) {
                String siblingName = sibling.getName();
                // Get the sibling name, excluding any .html suffix
                String newSiblingFolderName = siblingName.substring(0, siblingName.indexOf(".html"));
                // Create a folder with that name
                CmsResource createdSiblingFolder = cmso.createResource(FOLDER_EN.concat(newSiblingFolderName), CmsResourceTypeFolder.RESOURCE_TYPE_ID);
                // Move the sibling from its current location into the newly created folder, making it the folder's index file
                cmso.lockResource(siblingPath);
                cmso.moveResource(siblingPath, cmso.getSitePath(createdSiblingFolder).concat("index.html"));
                cmso.unlockResource(cmso.getSitePath(createdSiblingFolder));
                out.println("Successfully moved sibling <code>" + siblingPath + "</code> correspondingly<br />");
            }
        }
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
    
}
%>