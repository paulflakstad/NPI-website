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
final String FOLDER = "/no/ansatte/";


// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

// Resource type and element names
final String RESOURCE_TYPE_NAME     = "person"; //"person";
final String XML_ELEMENT_IMAGE   = "Image";

final boolean SUB_TREE = true;

// Source and destination locales
final Locale LOCALE_COPY_FROM = new Locale("no");
final Locale LOCALE_COPY_TO = new Locale("en");
// Elements to copy
Set<String> elements = new HashSet<String>();
elements.add(XML_ELEMENT_IMAGE);


// Filter for resource type "person"
CmsResourceFilter rf = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

//List filesInFolder = cmso.getFilesInFolder(FOLDER, rf);
List filesInFolder = cmso.readResources(FOLDER, rf, SUB_TREE);

out.println("<h3>Collected " + filesInFolder.size() + " resources.</h3>");

Iterator iFilesInFolder = filesInFolder.iterator();
while (iFilesInFolder.hasNext()) {
    CmsResource fileResource = (CmsResource)iFilesInFolder.next();
    // Get the file name
    String fileName = fileResource.getName();
    // Get the file path
    String filePath = cmso.getSitePath(fileResource);
    out.println("<hr /><h4>Processing file <code>" + filePath + " (" + fileName + ")</code>...</h4>");
    
    try {
        
        CmsFile xmlContentFile = cmso.readFile(fileResource);
        // build up the xml content instance
        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
        
        I_CmsXmlContentValue elementValue = xmlContent.getValue(XML_ELEMENT_IMAGE, LOCALE_COPY_FROM);
        if (elementValue != null) {
            String elementValueString = elementValue.getStringValue(cmso);
            boolean copied = false;
            if (!xmlContent.hasValue(XML_ELEMENT_IMAGE, LOCALE_COPY_TO)) {
                //xmlContent.copyLocale(LOCALE_COPY_FROM, LOCALE_COPY_TO, elements);
                
                xmlContent.addValue(cmso, XML_ELEMENT_IMAGE, LOCALE_COPY_TO, 0).setStringValue(cmso, elementValueString);
                copied = true;
                out.println("Adding new element...<br />");
                
            } else if (xmlContent.getValue(XML_ELEMENT_IMAGE, LOCALE_COPY_TO).getStringValue(cmso).isEmpty()) {
                xmlContent.getValue(XML_ELEMENT_IMAGE, LOCALE_COPY_TO).setStringValue(cmso, elementValueString);
                copied = true;
                out.println("Replacing existing element...<br />");
            } else {
                out.println("A value already existed, unsafe to copy element.<br />");
            }
            if (copied) {
                //*// Write the changes
                cmso.lockResource(filePath);
                xmlContentFile.setContents(xmlContent.marshal());
                cmso.writeFile(xmlContentFile);    
                cmso.unlockResource(filePath);
                //*/
                out.println("Copied element " + XML_ELEMENT_IMAGE + ": '" + elementValueString + "'" +
                            " from " + LOCALE_COPY_FROM.getDisplayLanguage() + 
                            " to " + LOCALE_COPY_TO.getDisplayLanguage() + ".<br />");
                out.println("<em>Complete: file is written!</em><br />");
            }
        } else {
            out.println("No source value to copy.<br />");
        }
        
        
    } catch (Exception e) {
        out.println(getStackTrace(e));
    }
    
}
%>