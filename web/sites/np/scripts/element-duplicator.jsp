<%-- 
    Document   : element-duplicator.jsp
    Description: Copies an xmlcontent field's string value to another field.
    Created on : 01.jul.2010, 16:10:46
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>

<%@page import="java.util.*,
                org.opencms.jsp.*, 
                org.opencms.jsp.util.*,
                org.opencms.file.*,
                org.opencms.main.*,
                org.opencms.util.*,
                org.opencms.xml.*,
                org.opencms.xml.content.*,
                org.opencms.xml.types.*" %>
<html>
    <head>
    <title>Element duplicator</title>
    </head>
    <body>
<%
CmsJspXmlContentBean cms = new CmsJspXmlContentBean(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
Locale locale = cms.getRequestContext().getLocale();

// Define the resource type by its ID
final int TYPE = OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId();

// Process the current folder
final String FOLDER_PATH = cms.getRequestContext().getFolderUri();

// Path to dummy file
//final String RESOURCE_PATH = "/no/nyheter/arkiv/2009/2009-01-12-test.html";

// XPaths for the two fields
final String FROM_FIELD = "Paragraph/Image/URI";
final String TO_FIELD   = "TeaserImage";

// Whether or not to perform the copy _only_ if TO_FIELD is empty
final boolean copyOnlyIfMissing = true;


// Dummy list, for testing
/*List files = new ArrayList(1);
files.add(cmso.readResource(RESOURCE_PATH));*/
// Real list, fills with all resources in the folder
List files = cmso.getFilesInFolder(FOLDER_PATH, CmsResourceFilter.requireType(TYPE));

Iterator itr = files.iterator();
while (itr.hasNext()) {
    // The resource
    CmsResource res = (CmsResource)itr.next();
    // The file
    CmsFile resFile = cmso.readFile(res);
    // The file path
    String resPath = cmso.getSitePath(res);
    // The content, wrapped in an object for easy access
    CmsJspContentAccessBean content = new CmsJspContentAccessBean(cmso, res);
    
    out.println("<h4>Loading file <code>" + resPath + "</code></h4>");
    
    // Check if a value exists or if the field is empty
    String toFieldValue = ((CmsJspContentAccessValueWrapper)content.getValue().get(TO_FIELD)).getStringValue();
    if (!toFieldValue.isEmpty()) {
        out.println(TO_FIELD + ": <code>" + toFieldValue + "</code>");
    } else {
        out.println(TO_FIELD + " was empty or missing.");
    }
    
    out.println("<br />");
    
    String fromFieldValue = ((CmsJspContentAccessValueWrapper)content.getValue().get(FROM_FIELD)).getStringValue();
    if (!fromFieldValue.isEmpty()) {
        out.println(FROM_FIELD + ": <code>" + fromFieldValue + "</code>");
        
        if ((copyOnlyIfMissing && toFieldValue.isEmpty()) || !copyOnlyIfMissing) { // Then we should copy the value from the other element
            try {
                // Lock resource, so we'll be able to write
                cmso.lockResource(resPath);
                // Get the content
                CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, resFile);
                // Get the value of TO_FIELD (it may or may not be empty, but the element should exist)
                I_CmsXmlContentValue value = xmlContent.getValue(TO_FIELD, locale);
                // Set a new (String) value, by inserting the value of FROM_FIELD
                value.setStringValue(cmso, fromFieldValue);
                // Get the raw data
                byte[] changedRaw = xmlContent.marshal();
                
                out.println("<br/><em>Copied <code>" + fromFieldValue + "</code> from " + FROM_FIELD + " to " + TO_FIELD + ".</em>");
                //out.println("<h4>After copying</h4>");
                //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(changedRaw))) + "</pre>");

                // Set the file contents
                resFile.setContents(changedRaw);
                // Save changes
                cmso.writeFile(resFile);
                //cmso.unlockResource(resPath);
            } catch (Exception e) {
                out.println("<h4>Whoops, something crashed! Message: " + e.getMessage() + "</h4>");
            }
        }
    } else {
        out.println("No " + FROM_FIELD + " on this file.");
    }
}
%>
    </body>
</html>