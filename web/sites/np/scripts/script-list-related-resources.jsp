<%-- 
    Document   : related-resources.jsp
    Created on : Jan 4, 2013, 2:47:22 PM
    Author     : flakstad
--%><%@page contentType="text/html" pageEncoding="UTF-8"
%><%@page import="org.opencms.file.CmsObject,
                java.util.*,
                java.text.*,
                java.util.regex.*,
                org.opencms.main.CmsException,
                org.opencms.main.OpenCms,
                org.opencms.loader.CmsImageScaler,
                org.opencms.jsp.*,
                org.opencms.file.*,
                org.opencms.util.*,
                no.npolar.util.*" %><%!
/**
 * Gets a list of "auto-related" resources for a given resource.
 * @param relatedToUri The URI of the resource to find "auto-related" resources for
 */
public List getAutoRelatedResources(CmsObject cmso, String relatedToUri) throws CmsException {
    List list = cmso.readResourcesWithProperty("/", "uri.related"); 
    List<CmsResource> matches = new ArrayList<CmsResource>();

    Iterator itr = list.iterator();
    if (itr.hasNext()) {
        //out.println("<h5>Contending resources:</h5>");
        //out.println("<ul>");
        while (itr.hasNext()) {
            CmsResource r = (CmsResource)itr.next();
            //out.println("<li>" + cmso.getSitePath(r) + "</li>");
            String[] propStr = cmso.readPropertyObject(r, "uri.related", false).getValue("").split("\\|");
            for (int i = 0; i < propStr.length; i++) {
                //out.println("<!--\nChecking for match:\n" + propStr[i] + "\n" + lookupUri + "\n -->");
                if (propStr[i].equals(relatedToUri))
                    matches.add(r);
            }
        }
        //out.println("</ul>");
    }
    return matches;
}
%><%
CmsAgent cms                    = new CmsAgent(pageContext, request, response);
CmsObject cmso                  = cms.getCmsObject();
String requestFileUri           = cms.getRequestContext().getUri();
String requestFolderUri         = cms.getRequestContext().getFolderUri();
Locale locale                   = cms.getRequestContext().getLocale();
String loc                      = locale.toString();

final String MSG_INVALID_URI    = loc.equalsIgnoreCase("no") ? 
                                    "<h1>Kan ikke liste relaterte sider</h1><p>Filplasseringen manglet eller finnes ikke.</p>" 
                                    : "<h1>Cannot list related pages</h1><p>The file location was not given, or no such file exists.</p>";
final String LABEL_TITLE        = loc.equalsIgnoreCase("no") ? "Sider relatert til" : "Pages related to";
final String LABEL_PRIMARY      = loc.equalsIgnoreCase("no") ? "Prioriterte relaterte sider" : "Primary related pages";
final String LABEL_SECONDARY    = loc.equalsIgnoreCase("no") ? "Andre relaterte sider" : "Other related pages";
final String LABEL_GO_TO        = loc.equalsIgnoreCase("no") ? "Gå til siden" : "Go to the page";

cms.includeTemplateTop();

String lookupUri = request.getParameter("uri");

if (lookupUri == null || lookupUri.isEmpty() || !cmso.existsResource(lookupUri)) {
    out.println(MSG_INVALID_URI);
    cms.includeTemplateBottom();
    return;
}

String lookupUriRootPath = cmso.getRequestContext().getSiteRoot() + lookupUri;
Locale lookupLocale = new Locale(cmso.readPropertyObject(lookupUri, "locale", true).getValue("en"));

out.println("<h1>" + LABEL_TITLE + " &laquo;" + cms.property("Title", lookupUri, "[no title]") + "&raquo;</h1>");
out.println("<p><a href=\"" + lookupUri + "\">" + LABEL_GO_TO + " &laquo;" + cms.property("Title", lookupUri, "[no title]") + "&raquo;</a></p>");

// First, list all manually added related pages
String rpItems = "";
try {
    I_CmsXmlContentContainer container = cms.contentload("singleFile", lookupUri, null, null, lookupLocale, false);
    while (container.hasMoreContent()) {
        I_CmsXmlContentContainer rp = cms.contentloop(container, "RelatedPages");
        while (rp.hasMoreContent()) {
            I_CmsXmlContentContainer links = cms.contentloop(rp, "LinkListLink");
            while (links.hasMoreContent()) {
                String rpUri = cms.contentshow(links, "URI");
                rpItems += "<li>"
                                + "<h4><a href=\"" + rpUri + "\">" + cms.property("Title", rpUri, "[NO TITLE]") + "</a></h4>"
                                + "<p class=\"smalltext\">" + cms.property("Description", rpUri, "") + "</p>"
                            + "</li>";
            }
        }
    }
} catch (Exception e) {
    rpItems = "<li>Unable to retrieve manually added related pages: " + e.getMessage() + "</li>";
}

if (!rpItems.isEmpty()) {
    out.println("<h3>" + LABEL_PRIMARY + "</h3>");
    out.println("<div class=\"resourcelist smalltext\"><ul>" + rpItems + "</ul></div>");
}
/*
// Get all resources with a value set for this property
List list = cmso.readResourcesWithProperty("/", "uri.related"); 
List<CmsResource> matches = new ArrayList<CmsResource>();

Iterator itr = list.iterator();
if (itr.hasNext()) {
    //out.println("<h5>Contending resources:</h5>");
    //out.println("<ul>");
    while (itr.hasNext()) {
        CmsResource r = (CmsResource)itr.next();
        //out.println("<li>" + cmso.getSitePath(r) + "</li>");
        String[] propStr = cmso.readPropertyObject(r, "uri.related", false).getValue("").split("\\|");
        for (int i = 0; i < propStr.length; i++) {
            //out.println("<!--\nChecking for match:\n" + propStr[i] + "\n" + lookupUri + "\n -->");
            if (propStr[i].equals(lookupUriRootPath))
                matches.add(r);
        }
    }
    //out.println("</ul>");
}
*/
Iterator itr = getAutoRelatedResources(cmso, lookupUriRootPath).iterator();
if (itr.hasNext()) {
    out.println("<h3>" + LABEL_SECONDARY + "</h3>");
    
    out.println("<div class=\"resourcelist smalltext\">");
    out.println("<ul style=\"list-style:none; padding:0;\">");
    while (itr.hasNext()) {
        CmsResource r = (CmsResource)itr.next();
        out.println("<li>"
                        + "<h4><a href=\"" + cmso.getSitePath(r) + "\">" + cms.property("Title", cmso.getSitePath(r), "[NO TITLE]") + "</a></h4>"
                        + "<p class=\"smalltext\">" + cms.property("Description", cmso.getSitePath(r), "") + "</p>"
                    + "</li>");
    }
    out.println("</ul>");
    out.println("</div>");
}


cms.includeTemplateBottom();
%>