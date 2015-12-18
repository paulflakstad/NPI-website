<%-- 
    Document   : script-category-upgrade-processor
    Description: Upgrades content from old-style to new-style categories. 
                    More info in comments below.
    Created on : Dec 10, 2015, 6:08:56 PM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%>
<%@page import="org.opencms.main.CmsException"%>
<%@page import="org.dom4j.*" %>
<%@page import="org.opencms.relations.CmsLink"%>
<%@page import="org.opencms.util.CmsUUID"%>
<%@page import="java.util.*" %>
<%@page import="org.opencms.file.*" %>
<%@page import="org.opencms.jsp.CmsJspActionElement" %>
<%@page import="org.opencms.main.OpenCms" %>
<%@page import="org.opencms.relations.CmsRelationType" %>
<%@page import="org.opencms.util.*" %>
<%@page import="org.opencms.xml.*" %>
<%@page import="org.opencms.xml.content.*" %>
<%@page import="org.opencms.xml.types.*" %>
<%@page session="true" contentType="text/html" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%!
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
 * Generic write method - not used anywhere...
 */
public void writeChanges(CmsObject cmso, Object writeable, String resourceUri, byte[] raw, boolean persistChanges) throws CmsException {
    // Write file
    if ((writeable instanceof CmsFile || writeable instanceof CmsResource)) {
        CmsFile file = (CmsFile)writeable;
        file.setContents(raw);
        if (persistChanges) {
            cmso.writeFile(file);
        }
    } 
    
    // Write property
    else if ((writeable instanceof CmsProperty)) {
        CmsProperty property = (CmsProperty)writeable;
        property.setValue(new String(raw), CmsProperty.TYPE_INDIVIDUAL); // Write the value as individual

        if (persistChanges) {
            cmso.writePropertyObject(resourceUri, property); // getOrigin() was added in 
        }
    }
}
/**
 * Locker shortcut method.
 */
public void lock(CmsObject cmso, Object resourceOrUri, boolean alreadyLocked) throws CmsException {
    if (!alreadyLocked) {
        if (resourceOrUri instanceof CmsResource)
            cmso.lockResource((CmsResource)resourceOrUri);
        else if (resourceOrUri instanceof String) 
            cmso.lockResource((String)resourceOrUri);
    }
}
/**
 * Unlocker shortcut method.
 */
public void unlock(CmsObject cmso, Object resourceOrUri, boolean alreadyLocked) throws CmsException {
    if (!alreadyLocked) {
        if (resourceOrUri instanceof CmsResource)
            cmso.unlockResource((CmsResource)resourceOrUri);
        else if (resourceOrUri instanceof String) 
            cmso.unlockResource((String)resourceOrUri);
    }
}
%>
<!doctype html>
<html>
    <head>
        <title>Category upgrade processor</title>
        <style type="text/css">
            html {
                font-family:sans-serif;
                line-height:1.5em;
                font-size:0.9em
            }
            body {
                max-width:1200px;
                padding:2em 1rem;
                margin:0 auto;
            }
            section {
                background-color:#fafafa;
                margin:5rem 0;
                padding:1rem;
                box-shadow:1px 1px 2px rgba(0,0,0,0.25);
            }
            h2 {
                background-color:#ddd;
                color:#444;
                margin:1em -1rem;
                padding:1em;
                width:calc(100% - 1rem);
            } 
            h2:first-child {
                margin-top:-1rem;
            }
            code {
                font-family:monospace;
                background-color:#e3f2fc;
                padding:0.2em;
                border:1px solid #cdf;
                border-radius:3px;
            }
            pre {
                padding:1em;
                font-size:0.9em;
                line-height:0.6em;
                background:#eee;
            }
            .write,
            .done {
                display:block;
                padding:0.5em 1em;
                font-weight:bold;
                background-color:#beb;
                color:#fff;
            }
            .write {
                background-color:#ebb;
            }
        </style>
    </head>
    <body>
<%
    ////////////////////////////////////////////////////////////////////////////
    //
    // Preparations:
    // =============
    // 1. Identify all your resources that needs fixing
    // 2. Duplicate the _categories folder (entire subtree) as ".categories"
    // 3. Fix resource type schema -> change the category element:
    //      - type="OpenCmsString" ==> type="OpenCmsCategory"
    // 4. Customize settings for this script (below this comments section):
    //      - FOLDER should target a folder that contains 1 set of siblings
    //        (e.g. "/en/" or "/fr/"), not multiple siblings (e.g. "/")
    // 5. Make sure WRITE_CHANGES is set to false
    // 6: Do test run of script. (I.e. on a duplicate you've made for the test.)
    // 6. Once tests look good, set WRITE_CHANGES=true to make real changes
    //      - Note that REQUIRE_LOCKED_RESOURCES=true is always recommended
    //
    // ACHTUNG!
    // ========
    // All assigned categories will be moved into a single <Category> node. 
    // (Which in mostly OK, but may be undesirable in some cases.)
    // 
    // What it does:
    // =============
    // Changes "old" type XML for categories to "new" type. This is a required 
    // step when upgrading OpenCms from an old (_categories+TinyMCE) version to 
    // a newer (.categories+Acacia) version.
    //
    // Property mappings are also updated, and converted from the old 
    // pipe-separated format to the new comma-separated format.
    //
    // Example: This XML ("control code"):
    //      ...
    //      <Category><![CDATA[/sites/mysite/en/.categories/topic/climate/]]></Category>
    //      <Category><![CDATA[/sites/mysite/en/.categories/type/meeting/]]></Category>
    //      ...
    //
    // Will be changed to this:
    //      ...
    //      <Category>
    //        <link type="WEAK">
    //          <target><![CDATA[/sites/mysite/en/.categories/topic/climate/]]></target>
    //          <uuid>be8e9550-9e91-11e5-968d-d067e5371a66</uuid>
    //        </link>
    //        <link type="WEAK">
    //          <target><![CDATA[/sites/mysite/en/.categories/type/meeting/]]></target>
    //          <uuid>0b6aa3b1-9e92-11e5-968d-d067e5371a66</uuid>
    //        </link>
    //      </Category>
    //      ...
    // 
    //--------------------------------------------------------------------------
    //
    // Settings: Adapt to your specific use case
    //
    final String FOLDER                     = "/en/"; // The root folder to collect resources from
    final String RESOURCE_TYPE_NAME         = "np_event"; // The name of the resource type to target
    final String PROPERTY_NAME              = "collector.categories"; // The name of the property to which the categories are mapped
    final String XML_ELEMENT_CATEGORY       = "Category"; // The name of the XSD element that is the category
    final boolean READ_TREE                 = true; // Collect files in sub-tree?
    final boolean WRITE_CHANGES             = false; // false = test mode (no changes are written), true = actually write changes
    final boolean REQUIRE_LOCKED_RESOURCES  = true; // true = require the resources (or parent folder) to already be locked, false = attempt to acquire necessary locks automatically
    //
    // ==== DO NOT CHANGE CODE BELOW HERE! ====
    // ... unless you know what you're doing :)
    //
    ////////////////////////////////////////////////////////////////////////////
    
    
    
// Action element and CmsObject
CmsJspActionElement cms = new CmsJspActionElement(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();

// Resource type filter
final CmsResourceFilter FILTER = CmsResourceFilter.ALL.addRequireType(OpenCms.getResourceManager().getResourceType(RESOURCE_TYPE_NAME).getTypeId());

%>
<h1>Category upgrade – processing <code><%= FOLDER %></code> (+ siblings)</h1>
<%

// Collect files
List filesInFolder = cmso.readResources(FOLDER, FILTER, READ_TREE);
Iterator iFilesInFolder = filesInFolder.iterator();

// Process collected files
while (iFilesInFolder.hasNext()) {
    out.println("<section>");
    CmsResource collectedResource = (CmsResource)iFilesInFolder.next(); // Get the next collected resource
    // Read the file and build the xml content
    CmsFile xmlContentFile = cmso.readFile(collectedResource);
    CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, xmlContentFile);
    boolean modifiedXml = false;
    
    List<CmsResource> siblings = cmso.readSiblings(collectedResource, CmsResourceFilter.ALL);
    for (CmsResource resource : siblings) {
        String resourcePath = cmso.getSitePath(resource); 
        Locale locale = OpenCms.getLocaleManager().getDefaultLocale(cmso, resource);
        
        // The sibling's path is relative to the current site
        out.println("<h2>" + resourcePath + "</h2>");

        try {
            lock(cmso, resourcePath, REQUIRE_LOCKED_RESOURCES);
            
            out.println("<h3>Property processing: Get category path(s)</h3>");
            
            // Get the property object, which will be used to modify property value
            CmsProperty property = cmso.readPropertyObject(resource, PROPERTY_NAME, false);

            if (property.isNullProperty()) {
                out.println("<code>" + PROPERTY_NAME + "</code> was empty, skipping this file.");
                continue;
            }
                        
            ArrayList<String> pathsToExistingCategoryElements = new ArrayList<String>();
            List<String> availablePaths = xmlContent.getNames(locale);
            Iterator<String> iAvailablePaths = availablePaths.iterator();
            while (iAvailablePaths.hasNext()) {
                String path = iAvailablePaths.next();
                boolean isCatName = path.matches("^" + XML_ELEMENT_CATEGORY + "\\[\\d+\\]$");
                if (isCatName) {
                    pathsToExistingCategoryElements.add(path);
                }
            }
            
            String existingPropValue = property.getValue("");
            String newPropValue = "";
            if (!pathsToExistingCategoryElements.isEmpty()) {
                newPropValue = existingPropValue.replaceAll("\\|", ",").replaceAll("/_categories/", "/.categories/");
            } else {
                // Means: Property had a value, but no category node was found 
                // in the XML. This is an edge case, that typically occurs when 
                // a sibling is created from a resource that has a category set,
                // and then the next operation done on the sibling is removing 
                // any and all categories.
                // In these case, we retain a blank property value.
            }
            
            
            if (existingPropValue.equals(newPropValue)) {
                out.println("Existing value on property <code>" + PROPERTY_NAME + "</code> was good - no need to upgrade! :)");
                out.println("<br /> - Value was " + existingPropValue);
            } else {
                // Set and write the property value
                out.println("Upgrading value on property <code>" + PROPERTY_NAME + "</code>"
                            + "<br />Current value: <code>" + existingPropValue + "</code>"
                            + "<br />Upgrade value: <code>" + newPropValue + "</code>");

                // Write to object
                property.setValue(newPropValue, CmsProperty.TYPE_INDIVIDUAL); // Write the value as individual

                if (WRITE_CHANGES) {
                    // Write to file
                    out.println("<br />Writing property ...");
                    cmso.writePropertyObject(resourcePath, property);
                    out.println(" done!");
                }
            }

            
            
            out.println("<h3>XML content cleanup</h3>");

            out.println("<h4>Locale <code>" + locale + "</code></h4>");

            if (!pathsToExistingCategoryElements.isEmpty()) {
                
                out.println("Found " + pathsToExistingCategoryElements.size() + " existing <code>" + XML_ELEMENT_CATEGORY + "</code> node(s).");
                Iterator<String> iPathsToExistingCategoryElements = pathsToExistingCategoryElements.iterator();
                while (iPathsToExistingCategoryElements.hasNext()) {
                    String oldCatPath = iPathsToExistingCategoryElements.next();
                    out.print("<br /> - <code>" + oldCatPath + "</code> ");
                    Node existingCategoryNode = ((Node)xmlContent.getLocaleNode(locale)).selectSingleNode(oldCatPath);
                    
                    if (existingCategoryNode.selectSingleNode("link") == null) {
                        out.println("needs upgrade. Category folder was <code>" + existingCategoryNode.getText() + "</code>");
                    } else {
                        out.println("is good! :)");
                        iPathsToExistingCategoryElements.remove();// Remove this path, no need to modify
                    }
                }

                CmsXmlCategoryValue newCategoryValue;
                if (!pathsToExistingCategoryElements.isEmpty()) {
                    modifiedXml = true;
                    out.println("<br />Removing " + pathsToExistingCategoryElements.size() + " existing <code>" + XML_ELEMENT_CATEGORY + "</code> node(s) ...");
                    iPathsToExistingCategoryElements = pathsToExistingCategoryElements.iterator();
                    while (iPathsToExistingCategoryElements.hasNext()) {
                        String oldCatPath = iPathsToExistingCategoryElements.next();
                        xmlContent.removeValue(XML_ELEMENT_CATEGORY, locale, 0);
                        //out.println("<br /> - <code>" + oldCatPath + "</code> successfully removed");
                    }
                    out.println(" done!");


                    out.print("<p></p>Adding new, empty <code>" + XML_ELEMENT_CATEGORY + "</code> node ...");
                    newCategoryValue = (CmsXmlCategoryValue)xmlContent.addValue(cmso, XML_ELEMENT_CATEGORY, locale, 0);
                    out.println(" done!");

                    out.print("<br />Updating link(s) in new <code>"+ XML_ELEMENT_CATEGORY +"</code> node ...");
                    newCategoryValue.setStringValue(cmso, newPropValue); 
                    out.println(" done!");

                    out.println("<p></p>Done upgrading <code>" + XML_ELEMENT_CATEGORY + "</code> node. Result:");
                } else {
                    newCategoryValue = (CmsXmlCategoryValue)xmlContent.getValue(XML_ELEMENT_CATEGORY, locale, 0);
                    out.println("<p></p>Nothing modified in <code>" + XML_ELEMENT_CATEGORY + "</code> node. Keeping existing content:");
                }
                
                out.println("<pre>" + CmsStringUtil.escapeHtml(CmsXmlUtils.marshal(newCategoryValue.getElement(), "UTF-8")).replaceFirst("<br\\/>", "") + "</pre>");
            } else {
                out.println("No <code>" + XML_ELEMENT_CATEGORY + "</code> nodes to fix.");
            }


            out.println("<p></p><em>Done with this locale!</em>");
            
            unlock(cmso, resourcePath, REQUIRE_LOCKED_RESOURCES);
            
        } catch (Exception e) {
            out.println(getStackTrace(e));
            break;
        }
    } // for each sibling
    
    if (modifiedXml) {
        out.println("<p></p><span class=\"write\">Changes were made to the backing xml.");
        
        lock(cmso, collectedResource, REQUIRE_LOCKED_RESOURCES);

        if (WRITE_CHANGES) {
            try {
                xmlContent.validateXmlStructure(new CmsXmlEntityResolver(cmso));
            } catch (CmsXmlException e) {
                // enable "auto correction mode" - this is required or 
                // the xml will not be fully corrected
                xmlContent.setAutoCorrectionEnabled(true);
                // now correct the xml
                xmlContent.correctXmlStructure(cmso);
            }
        }
        xmlContentFile.setContents(xmlContent.marshal());

        //out.println("<h4>After change</h4>");
        //out.println("<pre>" + CmsStringUtil.escapeHtml( (new String(xmlContent.marshal())) ) + "</pre>");

        if (WRITE_CHANGES) {
            out.println(" Writing changes to file ...</span>");
            cmso.writeFile(xmlContentFile);
            out.println("<p></p><span class=\"done\">Done! :)</span>");
        } else {
            out.println("</span><p></p><span class=\"done\">All changes dropped – nothing written :)</span>");
        }

        unlock(cmso, collectedResource, REQUIRE_LOCKED_RESOURCES);
    } else {
        out.println("<p></p><span class=\"done\">No changes in the backing xml - file was good! :)</span>");
    }
    
    out.println("</section>");
} // for each collected file
%>
    </body>
</html>