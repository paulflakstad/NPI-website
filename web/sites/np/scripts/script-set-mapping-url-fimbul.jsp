<%-- 
    Document   : script-change-categories
    Created on : 16.mar.2011, 14:19:29
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
// Folder to read files from
final String FOLDER = "/no/forskning/ice/prosjekt/fimbulisen/nare1011/expedition-diary/entries/";


// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

final String RESOURCE_TYPE_NAME     = "newsbulletin";
final String XML_ELEMENT_NAME       = "MappingURL";


final boolean REQUIRE_LOCK          = true;
final boolean WRITE_CHANGES         = false;


// Filter for resource type
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

List filesInFolder = cmso.getFilesInFolder(FOLDER, rf);
Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file name
    String fileName = fileResource.getName();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    // Get a list of all siblings (includes the resource itself)
    List siblings = cmso.readSiblings(filePath, rf);
    out.println("<h4>Collected file <code>" + filePath + "</code> (plus " + (siblings.size() - 1) + " siblings)</h4>");
    
    // Folder to create
    //String newFolderName = fileName.substring(0, fileName.indexOf(".html"));
    
    try {
        if (!REQUIRE_LOCK) {
            // Lock the file
            cmso.lockResource(filePath);
        }
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        //out.println("<h3>Before modification</h3>");
        //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContentFile.getContents()))) + "</pre>");
        
        // Fix the teaser image
        List xmlContentElementValues = xmlContent.getValues(XML_ELEMENT_NAME, locale);
        Iterator iValues = xmlContentElementValues.iterator();
        if (iValues.hasNext()) { // use if instead of while, because there should be only one value
            I_CmsXmlContentValue value = (I_CmsXmlContentValue)iValues.next();
            String valueString = value.getStringValue(cmso);
            out.println(" - Value: " + valueString + "<br />");
            if (valueString.isEmpty()) {
                String replacementValueString = "http://fimbul.npolar.no/no/nare1011/expedition-diary/entries/" + fileName;
                out.println(" -- Replacement: <a href=\"" + replacementValueString + "\">" + replacementValueString + "</a><br />");
                out.print("<em>Attempting to change the value of " + value.getPath() + "... </em>");
                // Change the content value
                value.setStringValue(cmso, replacementValueString);
                out.println("OK!<br />");
            } else {
                out.println(" -- Replacement: NONE (value was OK)<br />");
            }
        }
        /*  
        if (xmlContent.validate(cmso).hasErrors())
            out.println("<strong>Errors when validating!</strong>");
        else
            out.println("<strong>No errors when validating!</strong>");
        */
        xmlContentFile.setContents(xmlContent.marshal());

        if (WRITE_CHANGES) {
        //cmso.writeResource(fileResource); // <-- does nothing...
            cmso.writeFile(xmlContentFile);
        }
        
        if (!REQUIRE_LOCK) {
            // Unlock the file
            cmso.unlockResource(filePath);
        }
        
        
        /*
        Set keys = replacements.keySet();
        Iterator iKeys = keys.iterator();
        while (iKeys.hasNext()) {
            String key = (String)iKeys.next();
            String replacementString = "<![CDATA[".concat((String)replacements.get(key)).concat("]]>");
            xmlContent.getValue(key, locale).setStringValue(cmso, replacementString);
        }
        */
        
        /*// For categories, one must also change the structured XML contents in the file,
        // it is not sufficient only to change the property value
        // Read the "collector.categories" property
        CmsProperty catProp = cmso.readPropertyObject(fileResource, "collector.categories", false);
        String catPropStringValue = catProp.getValue("");
        String[] categoryRootPaths = catPropStringValue.split("\\|");
        out.println("Found " + categoryRootPaths.length + " categories:<br />");
        String newCatPropStringValue = "";
        for (int i = 0; i < categoryRootPaths.length; i++) {
            newCatPropStringValue += NEW_CAT_FOLDER + catMap.get(categoryRootPaths[i].replace(OLD_CAT_FOLDER, ""));
            if (i+1 < categoryRootPaths.length)
                newCatPropStringValue += "|";
            out.println(" * " + categoryRootPaths[i] + " --- replacement: " + NEW_CAT_FOLDER + catMap.get(categoryRootPaths[i].replace(OLD_CAT_FOLDER, "")) + "<br />");
        }
        out.println("<ul><li>Old category.collector value: <code>" + catPropStringValue + "</code></li>");
        out.println("<li>New category.collector value: <code>" + newCatPropStringValue + "</code></li></ul>");
        
        
        cmso.lockResource(filePath);
        catProp.setValue(newCatPropStringValue, CmsProperty.TYPE_INDIVIDUAL);        
        cmso.writePropertyObject(filePath, catProp);
        */
        
        
        /*
        // Create a folder with the same name as the file (but without the .html suffix)
        CmsResource createdFolder = cmso.createResource(FOLDER_NO.concat(newFolderName), CmsResourceTypeFolder.RESOURCE_TYPE_ID);
        out.println("Created folder <code>" + cmso.getSitePath(createdFolder) + "</code><br />");
        
        cmso.lockResource(filePath);
        String newFilePath = cmso.getSitePath(createdFolder).concat("index.html");
        // Move the file from its current location into the newly created folder, making it the folder's index file
        cmso.moveResource(filePath, newFilePath);
        cmso.unlockResource(cmso.getSitePath(createdFolder));
        out.println("Successfully moved <code>" + filePath + "</code> to <code>" + newFilePath + "</code><br />");
        */
        
        
        
        /*
        //
        // Handle siblings
        //
        Iterator iSiblings = siblings.iterator();
        while (iSiblings.hasNext()) {
            CmsResource sibling = (CmsResource)iSiblings.next();
            String siblingPath = cmso.getSitePath(sibling);
            if (siblingPath.startsWith("/en/")) {
                String siblingName = sibling.getName();
                // Get the sibling name, excluding any .html suffix
                String newSiblingFolderName = siblingName.substring(0, siblingName.indexOf(".html"));
                // Create a folder with that name
                CmsResource createdSiblingFolder = cmso.createResource(FOLDER_EN.concat(newSiblingFolderName), CmsResourceTypeFolder.RESOURCE_TYPE_ID);
                // Move the sibling from its current location into the newly created folder, making it the folder's index file
                cmso.lockResource(siblingPath);
                cmso.moveResource(siblingPath, cmso.getSitePath(createdSiblingFolder).concat("index.html"));
                cmso.unlockResource(cmso.getSitePath(createdSiblingFolder));
                out.println("Successfully moved sibling <code>" + siblingPath + "</code> correspondingly<br />");
            }
        }
        */
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
    
}
%>