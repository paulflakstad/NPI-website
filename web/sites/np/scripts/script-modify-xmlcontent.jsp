<%-- 
    Document   : script-modify-xmlcontent
    Created on : Jan 21, 2016
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page import="java.util.*,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.CmsJspActionElement,
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
final String FOLDER = "/foo/";
// The resource type name
final String RESOURCE_TYPE_NAME = "my_type"; // E.g. "newsbulletin";
// The XML content element's path
final String XML_ELEMENT_PATH = "MyElementName"; // E.g. "Category"

// Old value (change FROM this)
final String OLD_VAL = "/sites/np/no/_categories/";
// New value (change INTO this)
final String NEW_VAL = "/sites/np/en/_categories/theme/";

// Set to true to actually write changes. (false = test mode, no changes written)
final Boolean WRITE_CHANGES = false;
// Require that resources be locked before running this script? (Typically true)
final boolean REQUIRE_LOCKED_RESOURCES = true;

//----------------------------------------------------------------------------//

CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
Locale locale = cms.getRequestContext().getLocale();

// Filter for resource type
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

// Get all files
List filesInFolder = cmso.getFilesInFolder(FOLDER, rf);
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    // Get the file resource
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file name
    String fileName = fileResource.getName();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    // Get a list of all siblings (includes the resource itself)
    //List siblings = cmso.readSiblings(filePath, rf);
    
    out.println("<h4>Collected file <code>" + filePath + " (" + fileName + ")</code>"
                //+ " plus " + (siblings.size() - 1) + " siblings"
                + "</h4>");
    
    // Flag modifications
    boolean fileModified = false;
    
    try {
        // Lock the file?
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.lockResource(filePath);
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // Build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        //out.println("<h3>Before modification</h3>");
        //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContentFile.getContents()))) + "</pre>");

        List elementValues = xmlContent.getValues(XML_ELEMENT_PATH, locale);
        Iterator iElementValues = elementValues.iterator();
        while (iElementValues.hasNext()) {
            I_CmsXmlContentValue elementValue = (I_CmsXmlContentValue)iElementValues.next();
            String elementValueString = elementValue.getStringValue(cmso);
            out.println(" - " + XML_ELEMENT_PATH + " value was '" + CmsStringUtil.escapeHtml(elementValueString) + "'<br />");
            if (elementValueString != null && elementValueString.equals(OLD_VAL)) {
                out.print(" -- Changing this value to '" + CmsStringUtil.escapeHtml(NEW_VAL) + "'&hellip;");
                // Change the content value
                elementValue.setStringValue(cmso, NEW_VAL);
                fileModified = true;
                out.println("OK!<br />");
            } else {
                out.println(" -- Skipping (nothing to change here)<br />");
            }
        }
        
        if (fileModified) {
            xmlContentFile.setContents(xmlContent.marshal());

            //out.println("<h3>After modification</h3>");
            //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContent.marshal()))) + "</pre>");

            // Write changes?
            if (WRITE_CHANGES) {
                out.print("Writing changes&hellip;");
                try {
                    cmso.writeFile(xmlContentFile);
                    out.print("Done!<br />");
                } catch (Exception e) {
                    out.println("FAILED! (" + e.getMessage() + ")<br />");
                }
            }
        }
        
        // Unlock?
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.unlockResource(filePath);
        
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
}
%>