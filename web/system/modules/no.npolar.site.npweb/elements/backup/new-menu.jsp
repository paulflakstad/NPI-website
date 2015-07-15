<%-- 
    Document   : new-menu.jsp
    Created on : 14.sep.2010, 19:29:17
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="org.opencms.jsp.*,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsObject,
                 org.opencms.security.CmsRoleManager,
                 org.opencms.security.CmsRole,
                 org.opencms.main.OpenCms,
                 java.io.IOException,
                 java.util.List,
                 java.util.ArrayList,
                 java.util.Locale,
                 java.util.Iterator,
                 java.util.Date,
                 no.npolar.common.menu.*,
                 no.npolar.util.*" session="true" 
%><%!
    public void printDropDown(JspWriter out, MenuItem mi) throws IOException {
        if (mi.isParent()) {
            List subItems = mi.getSubItems();
            Iterator itr = subItems.iterator();

            out.println("<ul" + (mi.getLevel() > 1 ? " class=\"snap-right\"" : " class=\"no-snap\"") + ">");
            while (itr.hasNext()) {
                MenuItem subItem = (MenuItem)itr.next();
                if (subItem.isParent()) {
                    out.print("<li class=\"has_sub\">" +
                                    "<a onmouseover=\"showSubMenu(this)\" href=\"" + subItem.getUrl() + "\">" +
                                        "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>" +
                                    "</a>");
                    printDropDown(out, subItem);
                }
                else {
                    out.print("<li>" +
                                    "<a href=\"" + subItem.getUrl() + "\">" +
                                        "<span class=\"navtext\">" + subItem.getNavigationText() + "</span>" +
                                    "</a>");
                } 
                out.println("</li>");
            }
            out.println("</ul>");
        }
        else {
            if (mi.getLevel() > 1) { // Do this _only_ for menu items below top level
                out.println("<li>" +
                                "<a href=\"" + mi.getUrl() + "\">" +
                                    "<span class=\"navtext\">" + mi.getNavigationText() + "</span>" +
                                "</a>" +
                            "</li>");
            }
        }
    }
%><%
// Create a JSP action element, and get the URI of the requesting file (the one that includes this menu)
CmsAgent                cms         = new CmsAgent(pageContext, request, response);
CmsObject               cmso        = cms.getCmsObject();
String                  resourceUri = cms.getRequestContext().getUri();
HttpSession             sess        = request.getSession();
CmsRoleManager          roleManager = OpenCms.getRoleManager();
boolean                 useNoSession= roleManager.hasRole(cms.getCmsObject(), CmsRole.VFS_MANAGER);
boolean                 localeChanged=false;
MenuFactory             mf          = null;
Menu                    menu        = null;
Locale                  locale      = cms.getRequestContext().getLocale();
String                  loc         = null;

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
// Done setting localization to session


loc = locale.toString();



// Existence check: menu file's name
String xml = request.getParameter("filename");
// If no parameter "filename" was set, try looking elsewhere for a filename/path
if (xml == null) {
    // If the requesting file is a menufile (then it has type ID 320), we set the menu path = the path to the requesting file
    if (cms.getCmsObject().readResource(resourceUri).getTypeId() == 320)
        xml = resourceUri;
    // If the file is of any other type, set the menu path to the value of the property XMLResourceUri (search parent folders for this property if not found)
    else {
        xml = cms.property("XMLResourceUri", "search");
        if (xml == null)
            xml = cms.property("menu-file", "search");
    }
}
// If the menu path has not been resolved at this point, throw an exception
if (xml == null)
    throw new NullPointerException("No path to menu file could be resolved.");
// Done with existence check




if (useNoSession == false) { // If useNoSession is true, the next section won't change anything
    // Determine if the menu has been updated since it was put in session, 
    // and if so, set the useNoSession variable:
    if (sess.getAttribute("menu") != null) { // Menu exists in session
        if (sess.getAttribute("menu_timestamp") == null) { // If a menu exists, but no timestamp, then regererate and set it
            useNoSession = true;
        } else { // Timestamp exists
            long menuStoreTime = ((Long)sess.getAttribute("menu_timestamp")).longValue();
            CmsResource menuResource = cms.getCmsObject().readResource(xml);
            if (menuResource.getDateLastModified() > menuStoreTime) {
                useNoSession = true;
            }
        }
    }
    // Done determining if the menu has been updated since it was put in session
}




// If the menu is not in session, or if the locale has changed, 
// or if the menu needs to be re-generated due to updates or user type
if (sess.getAttribute("menu") == null || useNoSession || localeChanged) {
    try {
        // Create a menu factory. This class extends CmsJspXmlContentBean, so we pass the page context, request and response.
        mf = new MenuFactory(pageContext, request, response);
        // Instanciate the menu object by letting the menu factory process the xml file that holds the menu data.
        menu = mf.createFromXml(xml);
        // Set menu expand mode: don't hide menu items not "in path"
        menu.setExpandMode(true);
        // Save the menu as a session variable
        sess.setAttribute("menu", menu);
        // Save the menu creation timestamp as a session variable
        sess.setAttribute("menu_timestamp", new Date().getTime());
        //out.println("<h4>Menu placed in session</h4>");
    } catch (Exception e) { 
        out.println("Could not create the menu from resource '" + xml + "': " + e.getMessage()); 
    }
}
else {
    // Menu is already generated and stored in the session - get it
    menu = (Menu)sess.getAttribute("menu"); 
}
     
// Set the requesting resource as current menu item (more correctly: _try_ to do it - it may not exist in the menu at all)
try {
    menu.setCurrent(resourceUri);
} catch (Exception e) {
    //
}
     
if (cms.template("mainmenu")) {
    
    // Get the menu items at levelrange 1 to 2 as a list, and an iterator.
    List leftsideNavLinks = menu.getSubMenu(1, 2);
    if (leftsideNavLinks.size() == 0) {
        menu.setTraversalTypePreorder();
        leftsideNavLinks = menu.getSubMenu(1, 2);
    }
    //out.println("<h5>leftsideNavLinks.size(): " + leftsideNavLinks.size() + "</h5>");
    //out.println("<h5>menu.getDepth(): " + menu.getDepth() + "</h5>");
    Iterator i = leftsideNavLinks.iterator();
    if (i.hasNext()) {
        out.println("<div class=\"naviwrap\">");
        out.println("<ul class=\"menu\">");
        while (i.hasNext()) { 
            MenuItem mi = (MenuItem)i.next();
            String html = ("<li class=\"navitem_lvl" + mi.getLevel() + "\"");
            if (mi.isCurrent())
                html += (" id=\"current_lvl" + mi.getLevel() + "\">");
            else {
                html += ">";
            }
            html += ("<a class=\"navlink_lvl" + mi.getLevel() + "\" href=\"" + mi.getUrl() + "\">" +
                        "<span class=\"navtext_lvl" + mi.getLevel() + "\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span>" +
                     "</a>" +
                     "</li>");
            out.println(html);
        }
        out.println("</ul>");
        out.println("</div> <!-- END menu -->");
    }
} // if (cms.template("mainmenu"))


//
// Top menu (displays toplevel menu items)
//
if (cms.template("topmenu")) {
    List menuItems = menu.getSubMenu(1, 1);
    if (!menuItems.isEmpty()) {
        out.println("<ul id=\"nav_topmenu\">");
        
        MenuItem mi = null;
        String html;
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            html = "<li";
            if (mi.isInPath())
                html += " class=\"inpath\"";
            html += ">"; // Done with <li> tag
            html += "<a href=\"" + mi.getUrl() + "\"><span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span></a>";
            html += "</li>";
            out.println(html);
        }
        out.println("</ul>");
    }
} // if (cms.template("topmenu"))

//
// Top menu (displays toplevel menu items)
//
if (cms.template("topmenu-dd")) {
    List menuItems = menu.getSubMenu(1, 1);
    if (!menuItems.isEmpty()) {
        out.println("<ul id=\"nav_topmenu\">");
        
        MenuItem mi = null;
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            out.print("<li");
            if (mi.isInPath())
                out.print(" class=\"inpath\"");
            out.print(">"); // Done with <li> tag
            out.print("<a" + (mi.isParent() ? " onmouseover=\"showSubMenu(this)\"" : "") + " href=\"" + mi.getUrl() + "\">" +
                          "<span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span>" +
                      "</a>");
            
            // Now the dropdown part
            printDropDown(out, mi);
            
            out.println("</li>");
            
        }
        out.println("</ul>");
    }
} // if (cms.template("topmenu"))


//
// Submenu (displays sublevel menu items)
//
if (cms.template("submenu")) {
    
    List menuItems = menu.getSubMenu(2);
    if (!menuItems.isEmpty()) {
        
        MenuItem mi = null;
        String html = "";
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            if (mi.getParent().isInPath()) {
                html += "<li class=\"navitem_lvl" + (mi.getLevel() - 1);
                if (mi.isInPath() || mi.getParent().isInPath())
                    html += " inpath";
                if (mi.isCurrent())
                    html += "\" id=\"current_lvl" + (mi.getLevel() - 1);
                html += "\">"; // Done with <li> tag
                html += "<a href=\"" + mi.getUrl() + "\"><span class=\"navtext\">" + mi.getNavigationText().replaceAll(" & ", " &amp; ") + "</span></a>";
                html += "</li>";
            }
        }
        if (html.length() > 0) {
            out.println("<ul id=\"nav_submenu\">");
            out.println(html);
            out.println("</ul>");
        }
    }
} // if (cms.template("submenu"))


//
// Breadcrumb navigation
//
if (cms.template("breadcrumb")) {
    // Fetch a list containing the current breadcrumb items
    List menuItems = menu.getCurrentPath();
    // Menu item object
    MenuItem mi = null;
    List breadCrumbs = new ArrayList();
    
    // The breadcrumb label to use (typically "You are here")
    final String BREADCRUMB_LABEL = "";//cms.label("label.sorpolen2011.breadcrumb");
    // The separator between items in the breadcrumb
    final String BREADCRUMB_ITEM_SEPARATOR = "/";//" &raquo; ";
    // The "home" URI - fetched from property, defaults to the locale folder if no property value is found
    final String HOME_URI = cms.link(cms.property("home-file", "search", "/".concat(loc).concat("/")));
    // The maximum length of the last breadcrumb item
    final int BC_TEXT_MAXLENGHT = 32;
    // Find the current request file URI, modify to remove "index.html" if needed
    if (resourceUri.endsWith("/index.html"))
        resourceUri = resourceUri.substring(0, resourceUri.lastIndexOf("index.html"));

    // Add the "home" menu item
    MenuItem homeMenuItem = new MenuItem(loc.equalsIgnoreCase("no") ? "Forsiden" : "Home", HOME_URI);
    if (!menuItems.isEmpty()) {
        if (!((MenuItem)(menuItems.get(0))).getUrl().equals(homeMenuItem.getUrl())) {
            menuItems.add(0, homeMenuItem);
        }
    } else {
        menuItems.add(0, homeMenuItem);
    }
    
    // Handle pages not referenced to in the menu
    if (menu.getElementByUrl(resourceUri) == null) {
        final String EMPLOYEES_FOLDER = loc.equalsIgnoreCase("no") ? "/no/ansatte/" : "/en/people/";
        final int TYPE_ID_PERSON = org.opencms.main.OpenCms.getResourceManager().getResourceType("person").getTypeId();
        final int TYPE_ID_PERSONALPAGE = org.opencms.main.OpenCms.getResourceManager().getResourceType("personalpage").getTypeId();
        final String EVENTS_FOLDER = loc.equalsIgnoreCase("no") ? "/no/hendelser/" : "/en/events/";
        final int TYPE_ID_EVENT = org.opencms.main.OpenCms.getResourceManager().getResourceType("np_event").getTypeId();
        String requestFileUri = cms.getRequestContext().getUri();
        
        // Handle the special case of "this is a page within an employee's section":
        // Each employee can have a "sub-site" - a set of pages inside their folder. But the menu contains only the employees folder.
        // So, to avoid breaking the breadcrumb, we must determine if we're viewing such a page, and if so, insert the employee's name
        // at the correct place, so we get f.ex.: Home -> Employees -> Paul-Inge Flakstad -> One of Paul's pages
        // (Not having this special handler would produce: Home -> Employees -> One of Paul's pages)
        if (requestFileUri.startsWith(EMPLOYEES_FOLDER)  // Require that we are inside the employees section
                && cmso.readResource(requestFileUri).getTypeId() != TYPE_ID_PERSON) { // AND require that the request file is NOT an employee's "main" page (that case is handled below)
            // The resource is within an employee's section
            //out.println("<!-- personalpage ID: " + TYPE_ID_PERSONALPAGE + " -->");
            //out.println("<!-- requested resource's ID: " + cmso.readResource(requestFileUri).getTypeId() + " -->");
            //out.println("<!-- requested resource's path: " + requestFileUri + " -->");
            boolean isMainPersonPage = cmso.readResource(requestFileUri).getTypeId() == TYPE_ID_PERSON;
            if (!isMainPersonPage) {
                
                //out.println("<!-- page is not of type person (" + TYPE_ID_PERSON + " / " + cmso.readResource(requestFileUri).getTypeId() + ") -->");
                // The resource is _not_ the "main" employee page,
                // assume that it is a page the employee has created himself/herself
                final String IMAGES_FOLDER = "/images/";
                String personFolderPath = cmso.readPropertyObject(requestFileUri, "gallery.startup", true).getValue(IMAGES_FOLDER).replace(IMAGES_FOLDER, "/");
                String personName = cms.property("Title", personFolderPath, "");
                MenuItem personMenuItem = new MenuItem(personName, personFolderPath);
                menuItems.add(personMenuItem);
                // Now add the page itself
                MenuItem personalPageItem = new MenuItem(cms.property("Title", requestFileUri, "NO TITLE"), requestFileUri);
                menuItems.add(personalPageItem);
            }
        }
        
        // Handle the special case of "this is a page within a specific event's folder":
        // Some events require more than one page - conferences and alike. Let's call them "big events". 
        // Big events have an event folder instead of a single event file. In this folder, all pages are placed.
        // We need to make sure the breadcrumb will reflect the event when viewing these pages.
        // For example: Home -> Events -> The big conference -> Programme
        // (Not having this special handler would produce: Home -> Events -> Programme)
        else if (requestFileUri.startsWith(EVENTS_FOLDER + "20") // Require that we are inside a sub-folder (a "year" folder) of the events folder
                && cmso.readResource(requestFileUri).getTypeId() != TYPE_ID_EVENT) { // AND require that the request file is NOT an event's "main" page (that case is handled below)
            // We're currently inside one of the "year" folders. We don't know yet if we're inside a big event's folder.
            // However, we can assume that if we find an index file in the current folder, it's a big event folder.
            // (The "year" folders should not directly contain index files themselves.)
            String bigEventIndexFilePath = cms.getRequestContext().getFolderUri().concat("index.html");
            if (cmso.existsResource(bigEventIndexFilePath) 
                    && cmso.readResource(bigEventIndexFilePath).getTypeId() == TYPE_ID_EVENT) {
                // There was an index file, and it was an event file. We can now safely assume that the current page is a big event page.
                // Now, to maintain breadcrumb integrity, insert the event's name
                String eventTitle = cmso.readPropertyObject(bigEventIndexFilePath, "Title", false).getValue("UNKNOWN EVENT");
                MenuItem eventMenuItem = new MenuItem(eventTitle, bigEventIndexFilePath.replace("/index.html", ""));
                menuItems.add(eventMenuItem);
                // Now add the page itself
                MenuItem eventSubpageItem = new MenuItem(cms.property("Title", requestFileUri, "NO TITLE"), requestFileUri);
                menuItems.add(eventSubpageItem);
            }
        }
        
        // This is the standard routine for handling the case where the current page is not in the menu.
        // (And in that case, we need to add it at the end of the breadcrumb.)
        else {
            // Get the current page's title
            String unknownMenuItemTitle = cms.property("Title", resourceUri, "NO TITLE");
            if (cms.getCmsObject().readResource(resourceUri).isFolder() && unknownMenuItemTitle.equals("NO TITLE")) {
                unknownMenuItemTitle = cms.property("Title", resourceUri.concat("index.html"), "NO TITLE");
            }
            // Add the current page as a final item in the breadcrumb, using its "Title" property as navigation text
            MenuItem unknownMenuItem = new MenuItem(unknownMenuItemTitle, (resourceUri));
            menuItems.add(unknownMenuItem);
        }
    }
    
    // Start the list
    String html = "<ul id=\"nav_breadcrumb\">";
    // First item: the breadcrumb label
    html += CmsAgent.elementExists(BREADCRUMB_LABEL) ? ("<li>" + BREADCRUMB_LABEL + ": </li>") : "";
            Iterator i = menuItems.iterator();
            while (i.hasNext()) {
                mi = (MenuItem)i.next();
                String navText = mi.getNavigationText().replaceAll(" & ", " &amp; ");
                // This text can potentially be excessively long, so shorten it if neccessary
                if (navText.length() > BC_TEXT_MAXLENGHT) {
                    navText = navText.substring(0, BC_TEXT_MAXLENGHT);
                    // Don't break in the middle of a word
                    navText = navText.substring(0, navText.lastIndexOf(" "));
                    // Add dots to illustrate that the text is shortened
                    navText += "&hellip;";
                }
                
                html += "<li>";
                if (i.hasNext()) // Not last item
                    html += "<a href=\"" + cms.link(mi.getUrl()) + "\" class=\"breadcrumb\">" + 
                            navText + "</a>" + BREADCRUMB_ITEM_SEPARATOR;
                else { // Last item
                    // Don't print the last item (the current page) as a link, only text
                    html += navText;
                }
                html += "</li>";
            }
    
    // End the breadcrumb list
    html += "</ul><!-- #nav_breadcrumb -->";
    // Print the breadcrumb as resolved above
    out.println(html);
    /*List menuItems = menu.getCurrentPath();
    if (!menuItems.isEmpty()) {
        out.println("<ul id=\"nav_breadcrumb\">");
        
        MenuItem mi = null;
        String html;
        Iterator i = menuItems.iterator();
        while (i.hasNext()) {
            mi = (MenuItem)i.next();
            html = "<li ";
            if (mi.isInPath() || mi.getParent().isInPath())
                html += " inpath";
            if (mi.isCurrent())
                html += "\" id=\"current_lvl" + (mi.getLevel() - 1);
            html += "\">"; // Done with <li> tag
            html += "<a href=\"" + mi.getUrl() + "\"><span class=\"navtext\">" + mi.getNavigationText() + "</span></a>";
            html += i.hasNext() ? "/" : "";
            html += "</li>";
            out.println(html);
        }
        out.println("</ul><!-- #nav_breadcrumb -->");
    }
    */
}
%>