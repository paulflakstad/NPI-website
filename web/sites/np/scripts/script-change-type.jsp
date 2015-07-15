<%-- 
    Document   : script-change-type
    Created on : May 7, 2013, 4:13:47 PM
    Author     : flakstad
--%><%@page import="org.opencms.main.OpenCms"%>
<%@page import="org.opencms.file.CmsResourceFilter"%>
<%@ page import="no.npolar.util.CmsAgent,
                 java.util.Locale,
                 java.util.Date,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Iterator,
                 java.text.SimpleDateFormat,
                 org.opencms.jsp.I_CmsXmlContentContainer,
                 org.opencms.xml.*,
                 org.opencms.xml.content.*,
                 org.opencms.file.*,
                 org.opencms.relations.CmsCategoryService,
                 org.opencms.relations.CmsCategory,
                 org.opencms.util.CmsUUID" session="true" %>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>JSP Page</title>
    </head>
    <body>
        <h1>Convert resources</h1>
<%
// Action element and CmsObject
CmsAgent cms                        = new CmsAgent(pageContext, request, response);
CmsObject cmso                      = cms.getCmsObject();
// Commonly used variables
String requestFileUri               = cms.getRequestContext().getUri();
String requestFolderUri             = cms.getRequestContext().getFolderUri();
Locale locale                       = cms.getRequestContext().getLocale();
String loc                          = locale.toString();

int TYPE_ID_IVORYPAGE = 501;
int TYPE_ID_SPECIESPAGE = 305;

List resources = cmso.readResources(requestFolderUri, CmsResourceFilter.DEFAULT_FILES.requireType(TYPE_ID_IVORYPAGE), false);
Iterator<CmsResource> i = resources.iterator();
while (i.hasNext()) {
    CmsResource r = i.next();
    CmsFile f = cmso.readFile(r);
    
    // build up the xml content instance
    CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, f);
    CmsXmlContentDefinition def = xmlContent.getContentDefinition();
    
    
    String xml = new String(f.getContents());
    
    out.println("<h2>Original:</h2><pre>" + xml + "</pre>");
    
    xml = xml.replace("no.npolar.common.ivorypage/schemas/ivorypage.xsd", "no.npolar.common.species/schemas/species.xsd");
    xml = xml.replaceAll("<IvoryPage", "<SpeciesPage");
    xml = xml.replaceAll("<IvoryPages", "<SpeciesPages");
    xml = xml.replaceAll("</IvoryPage", "</SpeciesPage");
    xml = xml.replaceAll("</IvoryPages", "</SpeciesPages");
    
    out.println("<h2>Modified:</h2><pre>" + xml + "</pre>");
    
    f.setContents(xml.getBytes());
    cmso.writeFile(f);
    r.setType(TYPE_ID_SPECIESPAGE);
    CmsProperty p = cmso.readPropertyObject(r, "template-elements", false);
    if (p.isNullProperty()) {
        p = new CmsProperty("template-elements", null, null, true);
    }   
    p.setValue("/system/modules/no.npolar.common.species/elements/species.jsp", CmsProperty.TYPE_SHARED);
    cmso.writePropertyObject(cmso.getSitePath(r), p);
    cmso.writeResource(r);
    out.println("<br /> - Converted file: <em>" + cmso.readPropertyObject(r, "Title", false).getValue() + "</em>");
}
%>
    </body>
</html>
