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
// Folders to read files from
//final String FOLDER = "/no/om-oss/nyheter/arkiv/2006/";// "/no/ansatte/";
final String FOLDER = "/en/about-us/news/archive/2010/q1/";// "/no/ansatte/";
//final String FOLDER_EN = "/en/people/";


// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

final String RESOURCE_TYPE_NAME     = "newsbulletin"; //"person";
final String XML_ELEMENT_CATEGORY   = "Category";

final String OLD_CAT_FOLDER         = "/sites/np/en/_categories/";
//final String NEW_CAT_FOLDER         = "/sites/np/no/_categories/tema/";
final String NEW_CAT_FOLDER         = "/sites/np/en/_categories/theme/";

Map catMap = new HashMap();
catMap.put("antarctic/", "antarktis/");
catMap.put("arctic/", "arktis/");
catMap.put("barents/", "arktis/");
catMap.put("svalbard/", "arktis/");
catMap.put("climate/", "klima/");
catMap.put("env-toxins/", "miljogift/");
catMap.put("geology/", "geo/");
catMap.put("npi/", "np/");
catMap.put("research/", "forskning/");
catMap.put("sea-ice-snow/", "isbre/");
catMap.put("wildlife/", "dyr/");


// Filter for resource type "person"
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
    out.println("<h4>Collected file <code>" + filePath + " (" + fileName + ")</code> plus " + (siblings.size() - 1) + " siblings</h4>");
    
    // Folder to create
    //String newFolderName = fileName.substring(0, fileName.indexOf(".html"));
    
    try {
        // Lock the file
        cmso.lockResource(filePath);
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        //out.println("<h3>Before modification</h3>");
        //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContentFile.getContents()))) + "</pre>");

        
        List categoryValues = xmlContent.getValues(XML_ELEMENT_CATEGORY, locale);
        Map replacements = new HashMap();
        //List categoryValues = xmlContent.getValues(locale);
        Iterator iCategoryValues = categoryValues.iterator();
        while (iCategoryValues.hasNext()) {
            I_CmsXmlContentValue catValue = (I_CmsXmlContentValue)iCategoryValues.next();
            String catValueString = catValue.getStringValue(cmso);
            out.println(" - Category: " + catValueString + "<br />");
            if (catMap.get(catValueString.replace(OLD_CAT_FOLDER, "")) != null) {
                String replacementCatValueString = NEW_CAT_FOLDER + catMap.get(catValueString.replace(OLD_CAT_FOLDER, ""));
                out.println(" -- Replacement: " + replacementCatValueString + "<br />");
                out.print("<em>Attempting to change the value of " + catValue.getPath() + "... </em>");
                // Change the content value
                catValue.setStringValue(cmso, replacementCatValueString);
                out.println("OK!<br />");
                //xmlContent.getValue(catValue.getPath(), locale).setStringValue(cmso, replacementCatValueString);
                //replacements.put(catValue.getPath(), replacementCatValueString);
            } else {
                out.println(" -- Replacement: None, value was OK<br />");
            }
            //out.println(" - Path: " + catValue.getPath() + "<br />");
        }
        /*  
        if (xmlContent.validate(cmso).hasErrors())
            out.println("<strong>Errors when validating!</strong>");
        else
            out.println("<strong>No errors when validating!</strong>");
        */
        xmlContentFile.setContents(xmlContent.marshal());
        //cmso.writeResource(fileResource); // <-- does nothing...
        
        //out.println("<h3>After modification</h3>");
        //out.println("<pre>" + CmsStringUtil.escapeHtml((new String(xmlContent.marshal()))) + "</pre>");

        
        cmso.writeFile(xmlContentFile);
        
        
        
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