<%-- 
    Document   : menu-quicklinks
    Created on : 24.nov.2010, 12:47:44
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@ page import="org.opencms.jsp.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.security.CmsRoleManager,
                 org.opencms.security.CmsRole,
                 org.opencms.main.OpenCms,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Locale,
                 java.util.Iterator,
                 java.util.Date,
                 no.npolar.common.menu.*,
                 no.npolar.util.*" session="true" 
%><%


// Menu item separator
final String QUICKLINKS_SEPARATOR = "|";
// Create a JSP action element, and get the URI of the requesting file (the one that includes this menu)
CmsAgent cms                = new CmsAgent(pageContext, request, response);
String requestResourceUri   = cms.getRequestContext().getUri();
MenuFactory mf              = null;
Menu menu                   = null;
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();


//
// Determine the URI to the menu file
//
String xml = request.getParameter("resourceUri");
// If no parameter "resourceUri" was set, try looking elsewhere for a filename/path
if (xml == null) {
    // If the requesting file is a menufile (then it has type ID 320), we set the menu path = the path to the requesting file
    if (cms.getCmsObject().readResource(requestResourceUri).getTypeId() == 320)
        xml = requestResourceUri;
    // If the file is of any other type, set the menu path to the value of the property menu-file (search parent folders for this property if not found)
    else {
        xml = cms.property("menu-file", "search");
        if (xml == null)
            xml = cms.property("XMLResourceUri", "search"); // This property was used in earlier days
    }
}
// If the menu URI has not been resolved at this point, throw an exception
if (xml == null)
    throw new NullPointerException("Unable to determine an URI for the menu file.");




// Create the menu instance
try {
    // Create a menu factory. This class extends CmsJspXmlContentBean, so we pass the page context, request and response.
    mf = new MenuFactory(pageContext, request, response);
    // Instanciate the menu object by letting the menu factory process the xml file that holds the menu data.
    menu = mf.createFromXml(xml);
    // Set menu expand mode to "true": don't hide menu items not "in path"
    menu.setExpandMode(true);
} catch (Exception e) { 
    out.println("Could not create the menu from resource '" + xml + "': " + e.getMessage()); 
}


out.println("<!-- Quicklinks -->");
//
// Quicklinks menu
//
//if (cms.template("quicklinks")) {
    List menuItems = menu.getElements();
    if (!menuItems.isEmpty()) {
        out.println("<ul id=\"nav_quicklinks\">");
        
        MenuItem mi = null;
        String html;
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            html = "<li>" + QUICKLINKS_SEPARATOR + "&nbsp;";
            html += "<a href=\"" + mi.getUrl() + "\" class=\"quicklink\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ").trim() + "</a>";
            html += "&nbsp;";
            if (!i.hasNext()) // ==> last item
                html += QUICKLINKS_SEPARATOR;
            html += "</li>";
            out.print(html);
        }
        out.println("</ul>");
    } else {
        out.println("<!-- No menu items in menu file '" + xml + "'. -->");
    }
//} // if (cms.template("quicklinks"))
%>