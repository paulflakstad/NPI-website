<%-- 
    Document   : script-copy-property
    Created on : 29.apr.2011, 15:39:09
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 java.util.*,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.*,
                 org.opencms.file.types.*,
                 org.opencms.main.*,
                 org.opencms.util.CmsUUID,
                 org.opencms.xml.*,
                 org.opencms.xml.types.*,
                 org.opencms.xml.content.*,
                 org.opencms.util.*" session="true" %><%!
                 
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
// Folders to read files from
final String FOLDER_NO = "/no/ansatte/";
final String FOLDER_EN = "/en/people/";


// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

final String RESOURCE_TYPE_NAME     = "person";
final String PROPERTY_NAME          = "mapping-url";

final boolean SUB_TREE              = true;


// Filter for resource type "person"
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

List filesInFolder = cmso.readResources(FOLDER_NO, rf, SUB_TREE);// cmso.getFilesInFolder(FOLDER_NO, rf); // This will collect all employee folders
out.println("<h4>Using folder <code>" + FOLDER_NO + "</code>: collected " + filesInFolder.size() + " resources</h4>");
Iterator iFilesInFolder = filesInFolder.iterator();

int i = 0;
while (iFilesInFolder.hasNext()) {
    // Get the resource
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the resource name
    String fileName = fileResource.getName();
    // Get the employee folder path
    String filePath = cmso.getSitePath(fileResource);
    out.println("<hr />Processing file <code>" + filePath + "</code> ...<br />");
    // Get the property
    CmsProperty property = cmso.readPropertyObject(fileResource, PROPERTY_NAME, false);
    
    if (!property.isNullProperty() && !property.getValue("").isEmpty()) {
        String propertyValue = property.getValue();
        String modifiedPropertyValue = propertyValue.replace("/person/", "/english/person/");
        // Get a list of all siblings (includes the resource itself)
        List siblings = cmso.readSiblings(filePath, rf);
        out.println("<h5>Using locale <code>" + loc + "</code></h5>");
        out.println("<h5>Collected file <code>" + filePath + " (" + fileName + ")</code> plus " + (siblings.size() - 1) + " siblings</h5>");

        //
        // Copy the property value from this resource to its sibling in the other locale
        //
        Iterator iSiblings = siblings.iterator();
        while (iSiblings.hasNext()) {
            CmsResource sibling = (CmsResource)iSiblings.next();
            String siblingPath = cmso.getSitePath(sibling);
            if (siblingPath.startsWith("/en/")) {
                if (cmso.readPropertyObject(sibling, PROPERTY_NAME, false).getValue("").isEmpty()) {
                    //cmso.lockResource(siblingPath); // Commented out ==> Require (parent folder) lock to be present before running this script
                    property.setValue(modifiedPropertyValue, CmsProperty.TYPE_INDIVIDUAL);
                    cmso.writePropertyObject(siblingPath, property);
                    //cmso.unlockResource(siblingPath); // Commented out ==> Require (parent folder) lock to be present before running this script
                    out.println("<span style=\"background-color:green;\">Successfully modified sibling</span> <code>" + siblingPath + "</code>: " + PROPERTY_NAME + "=" + modifiedPropertyValue + ".<br />");
                } else {
                    out.println("<span style=\"background-color:red;\">Unsuccessful</span>: Property value already existed ('" + cmso.readPropertyObject(sibling, PROPERTY_NAME, false).getValue("") + "').<br />");
                }
            }
        }
    }
    i++;
}
%>