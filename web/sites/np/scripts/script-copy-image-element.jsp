<%-- 
    Document   : script-copy-image-element
    Created on : 6.jan.2014, 12:21:29
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
//
// Script for converting from old-version ivorypages (which uses two different 
// image elements), to the newer version (which uses a single "image" element).
//
// Any "old" image elements present are duplicated as new, generic image elements.
// The "old" image elements are not modified or removed.
//


// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();



final String FOLDER                 = "/no/spread/open-sea/distribution-maps/"; // Folder to read files from
final boolean INCLUDE_SUBFOLDERS    = true;
final String RESOURCE_TYPE_NAME     = "ivorypage"; // Resourcetype to modify
final String LOCALE                 = "no"; // Locale to modify

final boolean REQUIRE_LOCK          = true;
final boolean WRITE_CHANGES         = false;

Locale locale                       = new Locale(LOCALE);


// Filter for resource type
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

List filesInFolder = cmso.readResources(FOLDER, rf, INCLUDE_SUBFOLDERS); //cmso.getFilesInFolder(FOLDER, rf);

out.println("<h2>Collected " + filesInFolder.size() + " " + RESOURCE_TYPE_NAME + " resources from folder " + FOLDER + (INCLUDE_SUBFOLDERS ? " (including sub-tree)" : "") + "</h2>");

        
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    boolean modified = false;
    int imagesAdded = 0;
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    // Get a list of all siblings (includes the resource itself)
    List siblings = cmso.readSiblings(filePath, rf);
    out.println("<h4>Collected file <code>" + filePath + "</code> (plus " + (siblings.size() - 1) + " siblings)</h4>");
    
    try {
        if (!REQUIRE_LOCK) {
            // Lock the file
            cmso.lockResource(filePath);
        }
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        //List<Locale> locales = xmlContent.getLocales();
        
        // Get all element names
        List<String> elementNames = xmlContent.getNames(locale);
        // Sort them (Very important! This ensures that, for all images, the "parent" element is created first.)
        Collections.sort(elementNames);
        Collections.reverse(elementNames);
        
        Iterator<String> iElementNames = elementNames.iterator();
        if (iElementNames.hasNext()) {
            out.println("Element names:<br />");
            while (iElementNames.hasNext()) {
                String elementName = iElementNames.next();
                out.println(" - " + elementName + " <br />");
                
                // Match on e.g. Paragraph[1]/FillImage[1]  OR  Paragraph[4]/PosterImage[2] ?
                //if (elementName.matches("^Paragraph\\[\\d\\]/(FillImage|PosterImage)\\[\\d\\]+.*")) {
                if (elementName.matches("^Paragraph\\[\\d+\\]/(FillImage|PosterImage)\\[\\d+\\]$")) {
                    //out.println(" --- " + elementName + " is a match, adding value ... <br />");
                    /*// Resolve the index of the image 
                    // THIS CANNOT BE USED! We're narrowing 2 separate element sets down to 1, so if we do like this, some new images will be overwritten.
                    String imageIndexStr = elementName.substring(elementName.lastIndexOf("[") + 1);
                    imageIndexStr = imageIndexStr.substring(0, imageIndexStr.length()-1);
                    int index = Integer.valueOf(imageIndexStr) - 1;*/
                    
                    // Add the new image element. Note that all non-optional sub-elements are also added
                    String newElementName = elementName.replaceAll("(FillImage|PosterImage)", "Image").replaceFirst("\\[\\d+\\]$", "");
                    //if (xmlContent.getValue(newElementName, locale) == null) { // Prevent double-adding
                        try {
                            //xmlContent.addValue(cmso, newElementName, locale, index);
                            I_CmsXmlContentValue newElement = xmlContent.addValue(cmso, newElementName, locale, 0);
                            modified = true;
                            out.println(" - Added element " + newElement.getPath() + " &mdash; corresponds to " + elementName + ". <br />");
                            
                            
                            xmlContent.getValue(newElement.getPath().concat("/URI"), locale).setStringValue(cmso, xmlContent.getValue(elementName.concat("/URI"), locale).getStringValue(cmso));
                            //out.println(" -- Updated sub-element URI. <br />");
                            xmlContent.getValue(newElement.getPath().concat("/Title"), locale).setStringValue(cmso, xmlContent.getValue(elementName.concat("/Title"), locale).getStringValue(cmso));
                            //out.println(" -- Updated sub-element Title. <br />");
                            xmlContent.getValue(newElement.getPath().concat("/Text"), locale).setStringValue(cmso, xmlContent.getValue(elementName.concat("/Text"), locale).getStringValue(cmso));
                            //out.println(" -- Updated sub-element Text. <br />");
                            xmlContent.getValue(newElement.getPath().concat("/Source"), locale).setStringValue(cmso, xmlContent.getValue(elementName.concat("/Source"), locale).getStringValue(cmso));
                            out.println(" -- Updated sub-elements URI, Title, Text, Source. <br />");
                            
                            
                            // Set the new defaults + size
                            if (elementName.contains("FillImage")) {
                                xmlContent.getValue(newElementName.concat("/Size[1]"), locale).setStringValue(cmso, "M");
                                xmlContent.getValue(newElementName.concat("/Float[1]"), locale).setStringValue(cmso, "Right");
                                xmlContent.getValue(newElementName.concat("/ImageType[1]"), locale).setStringValue(cmso, "Photo");
                                out.println(" -- Updated defaults: size (M), float (Right), type (Photo).<br />");
                            }
                            else if (elementName.contains("PosterImage")) {
                                xmlContent.getValue(newElementName.concat("/Size[1]"), locale).setStringValue(cmso, "L");
                                xmlContent.getValue(newElementName.concat("/Float[1]"), locale).setStringValue(cmso, "After");
                                xmlContent.getValue(newElementName.concat("/ImageType[1]"), locale).setStringValue(cmso, "Photo");
                                out.println(" -- Updated defaults: size (L), float (After), type (Photo).<br />");
                            }
                        } catch (Exception e) {
                            out.println("ERROR adding / updating element " + newElementName + ": " + e.getMessage() + "<br />");
                        }
                            
                    //}
                }
                /*
                // Match on e.g. Paragraph[1]/FillImage[1]/URI[1]  OR  Paragraph[4]/PosterImage[2]/Text[1] ?
                else if (elementName.matches("^Paragraph\\[\\d\\]/(FillImage|PosterImage)\\[\\d\\]/(URI|Title|Text|Source)\\[\\d\\]$")) { 
                    out.println(" --- " + elementName + " is a match, updating value ... <br />");
                    
                    // Find the corresponding new element name
                    String newElementName = elementName.replaceAll("(FillImage|PosterImage)", "Image");
                    // Get the value from the "old" element
                    String elementValue = xmlContent.getValue(elementName, locale).getStringValue(cmso);
                    
                    if (xmlContent.getValue(newElementName, locale) == null 
                            || !xmlContent.getValue(newElementName, locale).getStringValue(cmso).equals(elementValue) ) { // Prevent double-adding
                        
                        try {    
                            // Copy it into the new element
                            xmlContent.getValue(newElementName, locale).setStringValue(cmso, elementValue);
                            modified = true;
                            out.println(" -- Updated element " + newElementName + ". <br />");
                        } catch (Exception e) {
                            out.println("ERROR updating element " + newElementName + ": " + e.getMessage() + "<br />");
                        }
                    }
                }
                */
            }
        }
        
        
        xmlContentFile.setContents(xmlContent.marshal());

        if (!modified) {
            out.println("<strong>No changes needed here.</strong>");
        }
        else {
            if (WRITE_CHANGES) {
                //cmso.writeResource(fileResource); // <-- does nothing...
                cmso.writeFile(xmlContentFile);
                out.println("<strong>Changes commited.</strong>");
            } else {
                out.println("<strong>Changes NOT commited. (To commit them, change the WRITE_CHANGES flag in this script.)</strong>");
            }
        }
        
        if (!REQUIRE_LOCK) {
            // Unlock the file
            cmso.unlockResource(filePath);
        }
        
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
    out.println("<hr />");
    
}
%>