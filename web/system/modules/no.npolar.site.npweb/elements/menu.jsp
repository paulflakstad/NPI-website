<%@ page import="org.opencms.main.OpenCms,
                 org.opencms.security.CmsRoleManager,
                 org.opencms.security.CmsRole,
                 org.opencms.jsp.*,
                 java.util.*,
                 org.opencms.main.*,
                 org.opencms.file.CmsUser,
                 org.opencms.security.CmsRole,
                 no.npolar.common.menu.*" 
%><%@ taglib prefix="cms" uri="http://www.opencms.org/taglib/cms" 
%><%
// Create a JSP action element, and get the URI of the requesting file (the one that includes this menu)
CmsJspXmlContentBean cms = new CmsJspXmlContentBean(pageContext, request, response);
String resourceUri = cms.getRequestContext().getUri();
Locale locale = cms.getRequestContext().getLocale();
HttpSession sess = request.getSession();
CmsRoleManager roleManager = OpenCms.getRoleManager();
boolean useNoSession = roleManager.hasRole(cms.getCmsObject(), CmsRole.VFS_MANAGER);
boolean localeChanged=false;


// Set localization as session attribute (need to re-generate the menu if the locale changes)
if (sess.getAttribute("locale") == null) {
    sess.setAttribute("locale", locale);
}
else {
    if (sess.getAttribute("locale") != locale) {
        localeChanged = true;
        sess.setAttribute("locale", locale);
    }
}

/* TESTING ROLE STUFF... */
/*
List userRoles = roleManager.getRolesForResource(cms.getCmsObject(), cms.user("name"), resourceUri);
Iterator ir = userRoles.iterator();
out.println("ROLES FOR USER " + cms.user("name") + "<br />");
while (ir.hasNext()) {
    out.println("ROLE: " + ((CmsRole)ir.next()).getRoleName() + "<br />");
}
out.println("User is " + (useNoSession ? "" : "NOT ") + "project manager");
*/ 
/***************/ 

MenuFactory mf = null;
Menu menu = null;

//if (useNoSession) out.println("<div style=\"background-color:#dd0000; color:white; text-align:center; padding:2px; \">Menu regenerated</div>");

if (cms.template("mainmenu")) {
    //if (true) {//sess.getAttribute("menu") == null) {
    //if (sess.getAttribute("menu") == null || useNoSession) {
    if (sess.getAttribute("menu") == null || useNoSession || localeChanged) {
        String xml = request.getParameter("filename");
        
	try {
        // If no parameter "filename" was set
        if (xml == null) {
            // If the requesting file is a menufile (then it has type ID 320), we set the menu path = the path to the requesting file
            if (cms.getCmsObject().readResource(resourceUri).getTypeId() == 320)
                xml = resourceUri;
            // If the file is of any other type, set the menu path to the value of the property XMLResourceUri (search parent folders for this property if not found)
            else
                xml = cms.property("XMLResourceUri", "search");
        }

        // If the menu path has not been resolved at this point, throw an exception
        if (xml == null)
            throw new NullPointerException("No path to menu file could be resolved.");

        // Create a menu factory. This class extends CmsJspXmlContentBean, so we pass the page context, request and response.
        mf = new MenuFactory(pageContext, request, response);
        // Instanciate the menu object by letting the menu factory process the xml file that holds the menu data.
        menu = mf.createFromXml(xml);
        menu.setExpandMode(true);

        sess.setAttribute("menu", menu);

	} 
        catch (Exception e) { out.println("An error occured while trying to resolve the path to the menu file. XML was '" + xml + "'"); }
    }
    else {
        menu = (Menu)sess.getAttribute("menu");
    }
    menu.setCurrent(resourceUri);
    
    // Get the menu items as a list, and an iterator
    //List navLinks = menu.getElementsParseHtml();
    List navLinks = menu.getElements();
    
    Iterator i = navLinks.iterator();
    MenuItem mi = null;
    String html = null;
    // Iterate over the list of menu items: print out items
    if (navLinks.size() > 0) {
        out.println("<ul class=\"menu\">");
        out.println("<!-- " + navLinks.size() + " elements total in the menu. -->");
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            html = "<li class=\"navitem_lvl" + mi.getLevel();
            if (mi.isInPath() || mi.getParent().isInPath())
                html += " inpath";
            if (mi.isCurrent())
                html += "\" id=\"current_lvl" + mi.getLevel();
            html += "\">"; // Done with <li> tag
            html += "<a href=\"" + mi.getUrl() + "\"><span class=\"navtext\">" + mi.getNavigationText() + "</span></a>";
            html += "</li>";
            out.println(html);
        }
        out.println("</ul>");
    }

    //out.println("<h4>Current menu item: " + (menu.getCurrent().getUrl() == null ? "No current element" : menu.getCurrent().getUrl()) + "</h4>");
    
}
%>