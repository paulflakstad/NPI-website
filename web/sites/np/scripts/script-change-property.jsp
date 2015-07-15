<%-- 
    Document   : script-change-property
    Created on : 16.mar.2011, 14:19:29
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.jsp.CmsJspActionElement,
                 java.util.List,
                 java.util.Iterator,
                 java.util.Locale,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.CmsProperty,
                 org.opencms.main.OpenCms" session="true" %><%!
                 
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
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
// Locale
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();
// Constants used in the script
final String FOLDER = "/your/content/folder/"; // Folders to collect files from
final String RESOURCE_TYPE_NAME = "your_resource_type_name"; // The type name of resources to collect
final String PROPERTY_NAME = "your_property_name"; // The name of the property to change
final String OLD_VALUE = "your_old_value"; // The old property value
final String NEW_VALUE = "your_new_value"; // The new property value
final boolean READ_TREE = true; // Collect files in sub-tree?
final boolean WRITE_CHANGES = false; // false = test mode (no changes are written), true = actually write changes
final boolean REQUIRE_LOCKED_RESOURCES = true; // true = require the resources (or parent folder) to already be locked, false = attempt to acquire necessary locks automatically
// Filter for the resource type
final CmsResourceFilter FILTER = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

// Collect files
List filesInFolder = cmso.readResources(FOLDER, FILTER, READ_TREE);
Iterator iFilesInFolder = filesInFolder.iterator();

// Process collected files
while (iFilesInFolder.hasNext()) {
    CmsResource resource = (CmsResource)iFilesInFolder.next(); // Get the next collected resource
    String resourceName = resource.getName(); // The collected resource's name
    String resourcePath = cmso.getSitePath(resource); // The collected resource's path, relative to the current site
    
    // Get a list of all siblings (includes the resource itself)
    List siblings = cmso.readSiblings(resourcePath, FILTER);
    
    // Print some info
    out.println("<h4>Collected file: <code>" + resourcePath + " (" + resourceName + ")</code> plus " + (siblings.size()-1) + " siblings</h4>");
    out.println("Using locale: <code>" + loc + "</code><br />");
        
    try {
        // Get the property object, which will be used to modify property value
        CmsProperty property = cmso.readPropertyObject(resource, PROPERTY_NAME, false);

        //
        // Here you could add check for whether or not the property needs to be written
        //
        
        // Handle case: null-property
        if (property.isNullProperty()) {
            property = new CmsProperty(PROPERTY_NAME, null, null, true);
        }        
        
        // Set and write the property value
        out.println("Writing (" + PROPERTY_NAME + "='" + NEW_VALUE + "' on resource " + resourcePath + ") ...<br />");
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.lockResource(resourcePath); // Lock resource
        property.setValue(NEW_VALUE, CmsProperty.TYPE_SHARED); // Write the value as shared
        property.setValue("", CmsProperty.TYPE_INDIVIDUAL); // Remove any individual value
        if (WRITE_CHANGES)
            cmso.writePropertyObject(resourcePath, property); // Write property on the resource
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.unlockResource(resourcePath); // Unlock resource
        
        
        // Handle siblings
        Iterator iSiblings = siblings.iterator();
        while (iSiblings.hasNext()) {
            CmsResource sibling = (CmsResource)iSiblings.next();
            String siblingPath = cmso.getSitePath(sibling);
            if (!siblingPath.equals(resourcePath)) {
                out.println("Processing sibling: <code>" + siblingPath + "</code><br />");
                // Do something with the sibling
            }
        }
        
        out.println("Done!<br />");
        out.println("<hr />"); 
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
}
%>
