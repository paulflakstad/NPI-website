<%-- 
    Document   : robots-txt-genny
    Created on : 08.mar.2011, 12:06:09
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
%><%!
public static List disallowed = new ArrayList();
/**
* Recursive method for creating a list of paths to resources that should not be 
* indexed by search engines. Returns a list of Strings, each string is a path to 
* a disallowed resource.
**/
public void populateDisallowedResourcesList(CmsAgent cms, String rootFolder, JspWriter out, boolean debugMode) throws IOException, CmsException {
    // Get the cms object
    CmsObject cmso = cms.getCmsObject();
    // The property that flags a resource as either indexable or non-indexable
    final String PROPERTY_ROBOTS_DISALLOW   = "robots.disallow";
    // Flag for collecting resources in sub-tree or just folder
    final boolean SUB_TREE = false;
    
    // Select a filter depending on offline / online project
    CmsResourceFilter filter = cms.getRequestContext().currentProject().isOnlineProject() ?
        // Filter: DEFAULT = Default filter to display resources for the online project
        CmsResourceFilter.DEFAULT :
        // Filter: ONLY_VISIBLE_NO_DELETED = Filter to display only visible and not deleted resources
        CmsResourceFilter.ONLY_VISIBLE_NO_DELETED;

    // Get all resources in the current root folder, using the above set filter (false = no sub-tree)
    List folderResoruces = cmso.readResources(rootFolder, filter, SUB_TREE);
    Iterator iFolderResources = folderResoruces.iterator();
    // Loop over all collected resources (files and folders)
    while (iFolderResources.hasNext()) {
        CmsResource res = (CmsResource)iFolderResources.next();
        String resSitePath = cmso.getSitePath(res);
        if (debugMode)
            out.println("<div style=\"border-bottom:1px solid #ddd; padding:0.25em 1em;\">" + 
                            "Processing resource <a href=\"" + cms.link(resSitePath) + "\">" + resSitePath + "</a> ...<br />");
        // Get the boolean flag which indicates if this resource should not be indexed by search engines ("indexable")
        boolean robotsDisallow = Boolean.valueOf(cmso.readPropertyObject(resSitePath, PROPERTY_ROBOTS_DISALLOW, false).getValue("false")).booleanValue();
        // If the resource is "not indexable", add its path in the list of disallowed resources
        if (robotsDisallow) {
            disallowed.add(resSitePath);
            if (debugMode)
                out.println("<span style=\"font-weight:bold; color:#900;\">*** Added to disallowed list. ***</span><br />");
        } 
        // If the resource is "indexable" AND the resource is a folder
        else if (res.isFolder()) {//getTypeId() == CmsResourceTypeFolder.getStaticTypeId()) {
            if (debugMode)
                out.println("-- <em>Folder, checking sub-tree...</em><br />");
            // Investigate down the sub-tree of the folder by calling this method recursively
            populateDisallowedResourcesList(cms, resSitePath, out, debugMode);
        }
        else {
            if (debugMode)
                out.println("-- <em>Not a folder, and available for indexing.</em><br />");
        }
        if (debugMode)
            out.println("</div>");
    }
}
%><%

///////////////////////////////////////////////
//
// Add any manual entries here
//
List manualEntries = new ArrayList();
manualEntries.add("/system/");
//manualEntries.add("/");
//
///////////////////////////////////////////////


CmsAgent cms                            = new CmsAgent(pageContext, request, response);
CmsObject cmso                          = cms.getCmsObject();
Locale locale                           = cms.getRequestContext().getLocale();
String requestFileUri                   = cms.getRequestContext().getUri();
String requestFolderUri                 = cms.getRequestContext().getFolderUri();

// Debug mode (off/on)
final boolean DEBUG_MODE    = false;

if (cmso.readResource(requestFileUri).getTypeId() == 
        OpenCms.getResourceManager().getResourceType("xmlpage").getTypeId()) {
    cms.include(requestFileUri, "body");
}

disallowed.clear();
disallowed.addAll(manualEntries);

if (DEBUG_MODE) {
    if (cms.getRequestContext().currentProject().isOnlineProject())
        out.println("<p><em>Using filter DEFAULT</em></p>");
    else
        out.println("<p><em>Using filter ONLY_VISIBLE_NO_DELETED</em></p>");
    out.println("<div style=\"height:250px; overflow:auto; border:1px solid #ccc; background:#eee; padding:0 1em;\">");
    populateDisallowedResourcesList(cms, requestFolderUri, out, DEBUG_MODE);
    out.println("</div>");
    Iterator iDisallowed = disallowed.iterator();
    out.println("<h3>Disallowed resources</h3>");
    out.println("<ul>");
    while (iDisallowed.hasNext()) {
        String disallowedResourcePath = (String)iDisallowed.next();
        out.println("<li>" + disallowedResourcePath + "</li>");
    }
}
else {
    populateDisallowedResourcesList(cms, "/", out, DEBUG_MODE);
    Iterator iDisallowed = disallowed.iterator();
    out.println("User-agent: *");
    while (iDisallowed.hasNext()) {
        String disallowedResourcePath = (String)iDisallowed.next();
        out.println("Disallow: " + disallowedResourcePath);
    }
}
%>