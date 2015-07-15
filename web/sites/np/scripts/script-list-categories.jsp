<%-- 
    Document   : script-list-categories
    Created on : 27 may 2011, 14:19:29
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="
                 java.util.*,
                 org.opencms.jsp.CmsJspActionElement,
                 org.opencms.file.*,
                 org.opencms.main.*,
                 org.opencms.xml.*,
                 org.opencms.xml.types.*,
                 org.opencms.xml.content.*" %><%
         
//  -----------------------------------------------
//  ########   Edit here to fit your test   #######
//  -----------------------------------------------
                 
// Folders to read resources from
final String FOLDER = "/";
// The name of the resource type to collect
final String RESOURCE_TYPE_NAME = "some_type";
// The name of the category element
final String XML_ELEMENT_CATEGORY = "Category";

//  #######   Don't edit below this line   ########
//  ##   (unless you know what you're doing :)   ##
//  -----------------------------------------------



// Commonly used stuffs
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
Locale locale = cms.getRequestContext().getLocale();

// The resource type filter
final CmsResourceFilter RF = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

// Collect resources
List filesInFolder = cmso.getFilesInFolder(FOLDER, RF);
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    // Get the next resource
    CmsResource resource = (CmsResource)iFilesInFolder.next();
    // Get the resource's site path
    String resourcePath = cmso.getSitePath(resource);
    // Print resource info
    out.println("<h4>Collected resource <code>" + resourcePath + " (" + cms.property("Title", resourcePath, "NO TITLE") + ")</code></h4>");
    
    try {
        // Lock the resource
        cmso.lockResource(resourcePath);
        // Build the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, cmso.readFile(resource));
        // Get the list of values for the element, and go through the list
        List categoryValues = xmlContent.getValues(XML_ELEMENT_CATEGORY, locale);
        if (!categoryValues.isEmpty()) {
            Iterator iCategoryValues = categoryValues.iterator();
            while (iCategoryValues.hasNext()) {
                // Get single value - this should be the category's root path
                I_CmsXmlContentValue catValue = (I_CmsXmlContentValue)iCategoryValues.next();
                // Convert to String, and print
                String catValueString = catValue.getStringValue(cmso);
                out.println(" - Category: " + catValueString + "<br />");
            }
        } else {
            // Be absolutely clear - print "no categories" info
            out.println("<em>No categories found here!</em>");
        }
        // Just to make it a tad more clear what's what ...
        out.println("<hr />");
        
    } catch (Exception e) {
        // Shouldn't happen, really ...
        e.printStackTrace(response.getWriter());
    }
}
%>