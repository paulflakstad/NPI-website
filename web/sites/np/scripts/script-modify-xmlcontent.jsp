<%-- 
    Document   : script-modify-xmlcontent
    Created on : Jan 21, 2016
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@ page import="java.util.*,
                 java.util.regex.*,
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
/**
 * Gets the indexed paths ("exact identifiers") that matches the given path.
 * <p>
 * The given path can be a more exact one, targeting one or more single specific 
 * elements, or it can be more like a general rule, targeting many elements.
 * <p>
 * Examples (given path => returned values):
 * <ul>
 * <li>"Image/URI" => "Image[1]/URI[1]" , "Image[2]/URI[1]" , "Image[3]/URI[1]"
 * <li>"Image[2]/URI" => "Image[2]/URI[1]"
 * <li>"Paragraph/Image[2]/URI" => "Paragraph[1]/Image[2]/URI[1]" , "Paragraph[2]/Image[2]/URI[1]"
 */
public List<String> getPaths(String path, Locale locale, CmsXmlContent content) {
    List<String> paths = new ArrayList<String>();
    
    if (Pattern.compile("\\[\\d\\]").matcher(path).find()) { // if ( path.has("\\[\\d\\]") )
        path = CmsXmlUtils.createXpath(path, 1); // Ensure that e.g. "Paragraph[2]/Image[1]/URI" becomes "Paragraph[2]/Image[1]/URI[1]"
    }
    
    for (String possiblePath : content.getNames(locale)) {
        if (path.equals("*") || possiblePath.equals(path) || possiblePath.replaceAll("\\[\\d\\]", "").equals(path)) {
            paths.add(possiblePath);
        }
    }
    return paths;
}
%><%
// Folders to read files from
final String FOLDER = "/foo/";
// The resource type name
final String RESOURCE_TYPE_NAME = "resource_type_name"; // E.g. "containerpage" or "newsbulletin"
// The XML content element's path
final String XML_ELEMENT_PATH = "ElementPath"; // E.g. "Category", or "Paragraph/Image/URI", or "Paragraph[3]/Image/URI", or even "*" (= match ANY element)

// Old value (change FROM this)
// Note that if you're working with links/URIs (e.g. images), provide the current site path (event though the control code uses the root path)
final String OLD_VAL = "something_to_remove"; // E.g. "/images/lolcat.gif"
// New value (change INTO this)
// Same note here - use site path
final String NEW_VAL = "something_to_insert"; // E.g. "/images/crazydog.png"

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
    
    out.println("<h3>Collected file <code>" + filePath + " (" + fileName + ")</code>"
                //+ " plus " + (siblings.size() - 1) + " siblings"
                + "</h3>");
    
    // Flag modifications
    boolean fileModified = false;
    
    try {
        // Lock the file?
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.lockResource(filePath);
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // Build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        //*
        out.println("<h4>Available paths in this file</h4><ul>");
        List<String> pathsInXml = xmlContent.getNames(locale);
        Iterator<String> iPathsInXml = pathsInXml.iterator();
        while (iPathsInXml.hasNext()) {
            out.println("<li>" + iPathsInXml.next() + "</li>");
        }
        out.println("</ul>");
        //*/
        
        //out.println("<h4>Before modification</h4>");
        //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContentFile.getContents()))) + "</pre>");

        List<String> paths = getPaths(XML_ELEMENT_PATH, locale, xmlContent);
        out.println("<p>" + paths.size() + " element(s) matched the path '" + XML_ELEMENT_PATH + "'. <em>Checking&hellip;</em></p>");
        for (String path : paths) {
            I_CmsXmlContentValue elementValue = xmlContent.getValue(path, locale);
            String elementValueString = null;
            try {
                elementValueString = elementValue.getStringValue(cmso);
            } catch (Exception e) {
                // nested element - skip it, can't change anything here
                continue;
            }
            out.println(" - '" + path + "' value was '" + CmsStringUtil.escapeHtml(elementValueString) + "'<br />");
            if (elementValueString != null && elementValueString.equals(OLD_VAL)) {
                out.print("<strong style=\"color:#c00;\"> -- Changing this value to '" + CmsStringUtil.escapeHtml(NEW_VAL) + "'&hellip;</strong><br />");
                // Change the content value
                elementValue.setStringValue(cmso, NEW_VAL);
                fileModified = true;
                out.println("OK!<br />");
            } else {
                out.println("<em> -- Skipping (nothing to change here)</em><br />");
            }
        }
        
        if (fileModified) {
            xmlContentFile.setContents(xmlContent.marshal());

            //out.println("<h4>After modification</h4>");
            //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContent.marshal()))) + "</pre>");

            // Write changes?
            if (WRITE_CHANGES) {
                out.print("<strong>Writing changes&hellip;");
                try {
                    cmso.writeFile(xmlContentFile);
                    out.print("Done!</strong><br />");
                } catch (Exception e) {
                    out.println("FAILED! (" + e.getMessage() + ")</strong><br />");
                }
            }
        }
        
        // Unlock?
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.unlockResource(filePath);
        
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
    out.println("<hr />");
}
%>