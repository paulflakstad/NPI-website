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
final String FOLDER_NO = "/no/ansatte/"; //"/no/om-oss/nyheter/arkiv/2006/"; 
final String FOLDER_EN = "/en/people/";


// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

final String RESOURCE_TYPE_NAME     = "person";// "newsbulletin";
final String XML_ELEMENT_CATEGORY   = "Category";
final String XML_ELEMENT_FIRSTNAME  = "GivenName";
final String XML_ELEMENT_LASTNAME   = "Surname";

final boolean READ_TREE             = true;


// Filter for resource type "person"
CmsResourceFilter filterRequirePerson = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());
CmsResourceFilter filterRequireFolder = CmsResourceFilter.ALL.addRequireType(CmsResourceTypeFolder.getStaticTypeId());

List filesInFolder = cmso.readResources(FOLDER_NO, filterRequirePerson, READ_TREE);// cmso.getFilesInFolder(FOLDER_NO, rf); // This will collect all employee folders
Iterator iFilesInFolder = filesInFolder.iterator();
int i = 0;
while (iFilesInFolder.hasNext()) {
    // Get the next resource
    CmsResource resource = (CmsResource)iFilesInFolder.next();
    // Get the resource's name
    String resourceName = resource.getName();
    // Get the resource's path, relative to the current site
    String resourcePath = cmso.getSitePath(resource);
    
    // Get a list of all siblings (includes the resource itself)
    List siblings = cmso.readSiblings(resourcePath, filterRequirePerson);
    out.println("<h4>Using locale <code>" + loc + "</code></h4>");
    out.println("<h4>Collected file <code>" + resourcePath + " (" + resourceName + ")</code> plus " + (siblings.size() - 1) + " siblings</h4>");
        
    try {
        // Setting property "gallery.startup"
        // 1. Get the file's parent folder
        String parentFolderPath = CmsResource.getParentFolder(resourcePath);
        CmsResource parentFolderResource = cmso.readResource(parentFolderPath);
        // 2. Create a new property instance, which will be used to write the new property value
        CmsProperty galleryStartupProperty = cmso.readPropertyObject(parentFolderResource, "gallery.startup", false);
        if (galleryStartupProperty.isNullProperty()) {
            galleryStartupProperty = new CmsProperty("gallery.startup", null, null, true);
        }
        // 3. Construct the property value
        String galleryPropertyValue = parentFolderPath.concat("images/");
        // 4. Set and write the property value
        out.println("<h4>Actucally writing (gallery.startup='" + galleryPropertyValue + "' on resource " + parentFolderPath + ")</h4>");
        //cmso.lockResource(parentFolderPath); // Commented out ==> Require (parent folder) lock to be present before running this script
        galleryStartupProperty.setValue(galleryPropertyValue, CmsProperty.TYPE_INDIVIDUAL);
        cmso.writePropertyObject(parentFolderPath, galleryStartupProperty); // Write property on the resource's parent folder
        //cmso.writePropertyObject(resourcePath, galleryStartupProperty); // Write property on the resource itself
        //cmso.unlockResource(parentFolderPath); // Commented out ==> Require (parent folder) lock to be present before running this script
        
        // Non-existing required resource: create it
        if (!cmso.existsResource(parentFolderPath.concat("images/"))) {
            CmsResource createdResource = cmso.createResource(parentFolderPath.concat("images/"), CmsResourceTypeFolder.getStaticTypeId());
            cmso.writeResource(createdResource);
            CmsProperty createdResourceTitle = new CmsProperty("Title", null, null);
            String parentFolderTitle = cmso.readPropertyObject(parentFolderPath, "Title", false).getValue("");
            createdResourceTitle.setValue("Personal images: ".concat(parentFolderTitle), CmsProperty.TYPE_INDIVIDUAL);
            cmso.writePropertyObject(cmso.getSitePath(createdResource), createdResourceTitle);
            out.println("<h4>Created image folder <code>" + cmso.getSitePath(createdResource) + "</code> ('" + createdResourceTitle.getValue("") + "')");
        }
        
        
        // Handle siblings
        Iterator iSiblings = siblings.iterator();
        while (iSiblings.hasNext()) {
            CmsResource sibling = (CmsResource)iSiblings.next();
            String siblingPath = cmso.getSitePath(sibling);
            if (siblingPath.startsWith("/en/")) {
                String siblingParentFolderPath = CmsResource.getParentFolder(siblingPath);
                //cmso.lockResource(siblingParentFolderPath); // Commented out ==> Require (parent folder) lock to be present before running this script
                galleryPropertyValue = siblingParentFolderPath.concat("images/");
                galleryStartupProperty.setValue(galleryPropertyValue, CmsProperty.TYPE_INDIVIDUAL);
                cmso.writePropertyObject(siblingParentFolderPath, galleryStartupProperty); // Write property on the sibling's parent folder
                //cmso.writePropertyObject(siblingPath, galleryStartupProperty); // Write property on the sibling itself
                //cmso.unlockResource(siblingParentFolderPath); // Commented out ==> Require (parent folder) lock to be present before running this script
                out.println("Successfully modified sibling folder <code>" + siblingParentFolderPath + "</code> correspondingly.<br />");
                
                // Non-existing required resource: create it
                if (!cmso.existsResource(siblingParentFolderPath.concat("images/"))) {
                    CmsResource createdResource = cmso.createResource(siblingParentFolderPath.concat("images/"), CmsResourceTypeFolder.getStaticTypeId());
                    cmso.writeResource(createdResource);
                    CmsProperty createdResourceTitle = new CmsProperty("Title", null, null);
                    String parentFolderTitle = cmso.readPropertyObject(siblingParentFolderPath, "Title", false).getValue("");
                    createdResourceTitle.setValue("Personal images: ".concat(parentFolderTitle), CmsProperty.TYPE_INDIVIDUAL);
                    cmso.writePropertyObject(cmso.getSitePath(createdResource), createdResourceTitle);
                    out.println("<h4>Created image folder <code>" + cmso.getSitePath(createdResource) + "</code> ('" + createdResourceTitle.getValue("") + "')");
                }
            }
        }
        
        out.println("<hr />");
        
        
        /*
        // Read the file (requires that the resource is of an XML / structured content type)
        CmsFile xmlContentFile = cmso.readFile(resource);
        // Build the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        //*/
        /*
        if (i == 0) {
            Iterator iNames = xmlContent.getNames(locale).iterator();
            out.println("<h5>Available names:</h5><ul>");
            while (iNames.hasNext()) {
                String xmlElementName = (String)iNames.next();
                out.println("<li>" + xmlElementName + " (" + xmlContent.getValue(xmlElementName, locale).getStringValue(cmso) + ")</li>");
            }
            out.println("</ul>");
        }
        */
        
        /*
        String titlePropertyString = "";
        String folderTitlePropertyString = "";
        //*/
        /*// Option 1: Set property only on resources with no property value (leave existing property values be)
        boolean needsTitle = false;
        if (cmso.readPropertyObject(fileResource, "Title", false).isNullProperty())
            needsTitle = true;
        //*/
        /*// Option 2: Set property on all resources (overwrite existing property values)
        boolean needsTitle = true;
        //*/
        
        
        
        
        /*
        CmsProperty titleProperty = cmso.readPropertyObject(resource, "Title", true);//new CmsProperty("Title", "", null);// cmso.readPropertyObject(fileResource, "Title", false);
        if (needsTitle) {
            I_CmsXmlContentValue firstNameValue = xmlContent.getValue(XML_ELEMENT_FIRSTNAME, locale);
            I_CmsXmlContentValue lastNameValue = xmlContent.getValue(XML_ELEMENT_LASTNAME, locale);
            if (firstNameValue != null && lastNameValue != null) {
                // Create the property value
                if (firstNameValue.getStringValue(cmso) != null && lastNameValue.getStringValue(cmso) != null) {
                    //titlePropertyString = firstNameValue.getStringValue(cmso);
                    //titlePropertyString += " " + lastNameValue.getStringValue(cmso);
                    titlePropertyString = lastNameValue.getStringValue(cmso) + ", " + firstNameValue.getStringValue(cmso);
                    folderTitlePropertyString = firstNameValue.getStringValue(cmso) + " " + lastNameValue.getStringValue(cmso);
                }
                //cmso.unlockResource(filePath);
                //cmso.lockResource(filePath);
                //titleProperty.setName("Title");
                if (titleProperty.isFrozen()) {
                    try {
                        titleProperty.setFrozen(false);
                    } catch (Exception e) {
                        out.println("<h5>***** Exception: unable to unfreeze the property " + titleProperty.getName() + "!</h5>");
                    }
                }
                else {
                    out.println("<h5>Property " + titleProperty.getName() + " was not frozen, writing ...</h5>");
                    // Lock the file and write the property
                    if (i >= 0) {
                        out.println("<h2>Actucally writing...</h2>");
                        cmso.lockResource(resourcePath);
                        titleProperty.setValue(titlePropertyString, CmsProperty.TYPE_INDIVIDUAL);
                        cmso.writePropertyObject(resourcePath, titleProperty);
                        cmso.unlockResource(resourcePath);
                        
                        // Write "firstname lastname" as the parent folder's Title
                        String parentFolderPath = CmsResource.getParentFolder(resourcePath);
                        cmso.lockResource(parentFolderPath);
                        titleProperty.setValue(folderTitlePropertyString, CmsProperty.TYPE_INDIVIDUAL);
                        cmso.writePropertyObject(parentFolderPath, titleProperty);
                        cmso.unlockResource(parentFolderPath);

                        
                        // Handle siblings
                        //
                        Iterator iSiblings = siblings.iterator();
                        while (iSiblings.hasNext()) {
                            CmsResource sibling = (CmsResource)iSiblings.next();
                            String siblingPath = cmso.getSitePath(sibling);
                            if (siblingPath.startsWith("/en/")) {
                                cmso.lockResource(siblingPath);
                                titleProperty.setValue(titlePropertyString, CmsProperty.TYPE_INDIVIDUAL);
                                cmso.writePropertyObject(filePath, titleProperty);
                                cmso.unlockResource(siblingPath);
                                out.println("Successfully modified sibling <code>" + siblingPath + "</code> correspondingly.<br />");
                                
                                // Write "firstname lastname" as the parent folder's Title
                                parentFolderPath = CmsResource.getParentFolder(siblingPath);
                                cmso.lockResource(parentFolderPath);
                                titleProperty.setValue(folderTitlePropertyString, CmsProperty.TYPE_INDIVIDUAL);
                                cmso.writePropertyObject(parentFolderPath, titleProperty);
                                cmso.unlockResource(parentFolderPath);
                            }
                        }
                    }
                }
                //
                //
                
                out.println("<li>Title value (NEW): <code>" + titlePropertyString + "</code> (file) and <code>" + folderTitlePropertyString + "</code> (folder)</li></ul>");
                
            } else {
                out.println("<li>UNABLE TO SET Title VALUE: No content to create title from.</li></ul>");
            }
            
            
            
        } else {
            out.println("<li> ** Title value (EXISTING): <code>" + titlePropertyString + "</code></li></ul>");
        }
        */
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
    i++;
}
%>