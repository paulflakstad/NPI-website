<%-- 
    Document   : personal-menu
    Created on : 29.sep.2011, 12:34:23
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 java.util.*,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.file.*,
                 org.opencms.file.types.*,
                 org.opencms.main.OpenCms,
                 org.opencms.main.CmsException,
                 org.opencms.util.CmsUUID" session="true" %><%!
                 
/**
* Gets an exception's stack strace as a string.
*/
public String getStackTrace(Exception e) {
    String trace = "";
    StackTraceElement[] ste = e.getStackTrace();
    for (int i = 0; i < ste.length; i++) {
        StackTraceElement stElem = ste[i];
        trace += stElem.toString() + "<br />";
    }
    return trace;
}

public String getResourceList(List resourceList, CmsObject cmso, CmsAgent cms) throws CmsException {
    String html = "";
    
    if (resourceList.size() > 0) {
        html += "<ul>";
        Iterator iFolderResources = resourceList.iterator();
        while (iFolderResources.hasNext()) {
            CmsResource pageResource = (CmsResource)iFolderResources.next();
            String pagePath = cmso.getSitePath(pageResource);
            String pageTitle = cms.property("Title", pagePath, "[NO TITLE");
            html += "<li><a href=\"" + cms.link(pagePath) + "\">" + pageTitle + "</a></li>";
        }
        html += "</ul>";
    }
    
    return html;
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

final boolean DEBUG = false;

final String IMAGES_FOLDER = "/images/";
final String RESOURCE_TYPE_NAME_PERSONALPAGE = "personalpage";


final int TYPE_ID_PERSON = org.opencms.main.OpenCms.getResourceManager().getResourceType("person").getTypeId();
final int TYPE_ID_PERSONALPAGE = org.opencms.main.OpenCms.getResourceManager().getResourceType("personalpage").getTypeId();
final int TYPE_ID_REQUEST_FILE = cmso.readResource(requestFileUri).getTypeId();

// Filter for resource type "personalpage"
CmsResourceFilter filterRequirePersonalpage = 
        CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME_PERSONALPAGE).getTypeId());

// Create the path to the person folder (e.g. "/en/people/paul.inge.flakstad/")
String personFolderPath = null;
if (TYPE_ID_REQUEST_FILE == TYPE_ID_PERSON) // Special case: the request page is the "main" personal page (resource type: "person")
    personFolderPath = requestFolderUri;
else
    personFolderPath = cmso.readPropertyObject(requestFileUri, "gallery.startup", true).getValue(IMAGES_FOLDER).replace(IMAGES_FOLDER, "/");

if (DEBUG) { out.println("<br />Evaluated person folder as: <code>" + personFolderPath + "</code>"); }

// Get a list of all subfolders inside this person's folder
List personalFolders = cmso.getSubFolders(personFolderPath);
// Remove the special "images" folder from the list of subfolders
personalFolders.remove(cmso.readResource(personFolderPath.substring(0, personFolderPath.length()-1).concat(IMAGES_FOLDER)));
if (DEBUG) { out.println("<br />Found " + personalFolders.size() + " subfolders"); }

// Get a list of all "personalpage" resources in the folder
List resourcesInFolder = cmso.readResources(personFolderPath, filterRequirePersonalpage, false);
if (resourcesInFolder.size() > 0) {
    String personName = cms.property("Title", personFolderPath, "");
    out.println("<h4><a href=\"" + cms.link(personFolderPath) + "\">" + personName + "</a>" + // Link to the main page
            "'" + (personName.endsWith("s") || personName.endsWith("z") ? "" : "s") + (loc.equalsIgnoreCase("no") ? " sider" : " pages") + "</h4>");
    out.println(getResourceList(resourcesInFolder, cmso, cms));


    Iterator iPersonalFolder = personalFolders.iterator();
    while (iPersonalFolder.hasNext()) {
        //
        CmsResource folderResource = (CmsResource)iPersonalFolder.next();

        String folderPath = cmso.getSitePath(folderResource);
        String folderTitle = cms.property("Title", folderPath, "[NO TITLE]");
        resourcesInFolder = cmso.readResources(folderPath, filterRequirePersonalpage);
        if (resourcesInFolder.size() > 0) {
            out.println("<h4>" + folderTitle + "</h4>");
            out.println(getResourceList(resourcesInFolder, cmso, cms));
            /*out.println("<ul>");
            Iterator iFolderResources = resourcesInFolder.iterator();
            while (iFolderResources.hasNext()) {
                CmsResource pageResource = (CmsResource)iFolderResources.next();
                String pagePath = cmso.getSitePath(pageResource);
                String pageTitle = cms.property("Title", pagePath, "[NO TITLE");
                out.println("<li><a href=\"" + cms.link(pagePath) + "\">" + pageTitle + "</a></li>");
            }
            out.println("</ul>");*/
        }
    }
}
%>