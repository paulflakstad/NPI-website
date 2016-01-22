<%-- 
    Document   : script-modify-xmlcontent
    Created on : Jan 21, 2016
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="java.util.ArrayList,
                    java.util.Iterator,
                    java.util.List,
                    java.util.Locale,
                    java.util.regex.Pattern,
                    java.text.SimpleDateFormat,
                    org.opencms.jsp.CmsJspActionElement,
                    org.opencms.file.CmsFile,
                    org.opencms.file.CmsObject,
                    org.opencms.file.CmsResource,
                    org.opencms.file.CmsResourceFilter,
                    org.opencms.main.OpenCms,
                    org.opencms.xml.CmsXmlUtils,
                    org.opencms.xml.types.I_CmsXmlContentValue,
                    org.opencms.xml.content.CmsXmlContent,
                    org.opencms.xml.content.CmsXmlContentFactory,
                    org.opencms.util.CmsStringUtil" 
            session="true"
%><%!                 
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
////////////////////////////////////////////////////////////////////////////////
//
// Settings: Adjust to your specific use case
//
// Path to the folder that contains the files to process
final String FOLDER = "/foo/";
// true => process all files under FOLDERS and any sub-folders, false => only process files located directly under FOLDER (not sub-folders)
final boolean READ_FOLDER_TREE = true;
// true => process all available locales, false => process only locale as set on FOLDER
final boolean PROCESS_ALL_LOCALES = false;
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

// true => actually write changes, false => no changes written ("test mode")
final Boolean WRITE_CHANGES = false;
// Require that resources be locked before running this script? (Typically true)
final boolean REQUIRE_LOCKED_RESOURCES = true;

// Display a list of all possible paths for each file?
final boolean DISPLAY_POSSIBLE_PATHS = true;
// Display the actual XML content before / after modification?
final boolean DISPLAY_XML_CHANGES = false;
//
// Done with settings
//
////////////////////////////////////////////////////////////////////////////////

CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();

// Initial locales list and add 1 item - the locale of FOLDER, or the default 
// locale, if FOLDER has no defined locale
// Note that this list will change (further down) if PROCESS_ALL_LOCALES==true
List<Locale> locales = new ArrayList<Locale>();
locales.add(OpenCms.getLocaleManager().getDefaultLocale(cmso, FOLDER));

// Filter for resource type
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

// Get all files
List filesInFolder = cmso.readResources(FOLDER, rf, READ_FOLDER_TREE); // cmso.getFilesInFolder(FOLDER, rf);
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    // Get the file resource
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    // Get a list of all siblings (includes the resource itself)
    //List siblings = cmso.readSiblings(filePath, rf);
    
    out.println("<div style=\"padding:0.5em; margin:0.5em 0; background-color:#f7f7f7;\">");
    out.println("<h2><code>" + filePath + "</code>"
                //+ " plus " + (siblings.size() - 1) + " siblings"
                + "</h2>");
    out.println("<div style=\"margin:0 0 0 2em;\">");
    
    // Flag modifications
    boolean fileModified = false;
    
    try {
        // Lock the file?
        if (!REQUIRE_LOCKED_RESOURCES)
            cmso.lockResource(filePath);
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // Build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        if (DISPLAY_XML_CHANGES) {
            out.println("<h3>Before modification</h3>");
            out.println("<pre style=\"line-height:0.6em; font-size:0.85em; padding:1em; background-color:#eee;\">" 
                            + CmsStringUtil.escapeHtml((new String(xmlContentFile.getContents()))) 
                        + "</pre>");
        }
        
        // Set up locales
        if (PROCESS_ALL_LOCALES) {
            locales = xmlContent.getLocales();
        }
        
        // Process XML content per locale
        for (Locale locale : locales) {
            
            if (DISPLAY_POSSIBLE_PATHS) {
                out.println("<h3>Available paths (in locale <code>" + locale.getLanguage() + "</code>)</h3><ul>");
                List<String> pathsInXml = xmlContent.getNames(locale);
                Iterator<String> iPathsInXml = pathsInXml.iterator();
                while (iPathsInXml.hasNext()) {
                    out.println("<li><code>" + iPathsInXml.next() + "</code></li>" + (iPathsInXml.hasNext() ? "" : "</ul>"));
                }
            }

            List<String> paths = getPaths(XML_ELEMENT_PATH, locale, xmlContent);
            out.println("<p>" + paths.size() + " element(s) matched the path <code>" + XML_ELEMENT_PATH + "</code>."
                            + (paths.isEmpty() ? " <em>Continuing&hellip;</em>" : " <em>Processing&hellip;</em>")
                        + "</p>");
            for (String path : paths) {
                I_CmsXmlContentValue elementValue = xmlContent.getValue(path, locale);
                String elementValueString = null;
                try {
                    elementValueString = elementValue.getStringValue(cmso);
                } catch (Exception e) {
                    // nested element - skip it, can't change anything here
                    continue;
                }
                out.println(" - <code>" + path + "</code> value was '<code>" + CmsStringUtil.escapeHtml(elementValueString) + "</code>'<br />");
                if (elementValueString != null && elementValueString.equals(OLD_VAL)) {
                    out.print("<strong style=\"background-color:#faa;\"> -- Changing this value to '<code>" + CmsStringUtil.escapeHtml(NEW_VAL) + "</code>'&hellip;</strong><br />");
                    // Change the content value
                    elementValue.setStringValue(cmso, NEW_VAL);
                    fileModified = true;
                    out.println("OK!<br />");
                } else {
                    out.println("<em> -- Skipping</em><br />"); // nothing to change here
                }
            }
        } // for (each locale)
        
        if (fileModified) {
            xmlContentFile.setContents(xmlContent.marshal());
            
            if (DISPLAY_XML_CHANGES) {
                out.println("<h3>After modification</h3>");
                out.println("<pre style=\"line-height:0.6em; font-size:0.85em; padding:1em; background-color:#eee;\">" 
                                + CmsStringUtil.escapeHtml((new String(xmlContent.marshal()))) 
                            + "</pre>");
            }

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
    out.println("</div>");
    out.println("</div>");
    out.println("<hr />");
}
%>