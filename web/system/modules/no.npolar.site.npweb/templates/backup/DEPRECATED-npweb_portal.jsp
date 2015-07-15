<%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.main.OpenCms,
		java.util.*,
                no.npolar.common.menu.*,
                no.npolar.util.CmsAgent"
%><%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Locale loc                  = cms.getRequestContext().getLocale();
String locale               = loc.toString();
String description          = cms.property("Description", requestFileUri, "");
String title                = cms.property("Title", requestFileUri, "");
boolean portal              = Boolean.valueOf(cms.property("portalpage", requestFileUri, "false")).booleanValue();
String canonical            = null;
String includeFilePrefix    = "";

// Handle case: canonicalization
// - Priority 1: a canonical URI is specified in the "canonical" property
// - Priority 2: the current request URI is an index file
CmsProperty propCanonical = cmso.readPropertyObject(requestFileUri, "canonical", false);
if (!propCanonical.isNullProperty()) {
    canonical = propCanonical.getValue();
    if (!cmso.existsResource(canonical))
        canonical = null;
}
if (canonical == null && requestFileUri.endsWith("/index.html")) {
    canonical = cms.link(requestFolderUri);
}

if (request.getParameter("__locale") != null) {
    loc = new Locale(request.getParameter("__locale"));
    cms.getRequestContext().setLocale(loc);
}
if (request.getParameter("includeFilePrefix") != null) {
    includeFilePrefix = request.getParameter("includeFilePrefix");
}

// Get the request file's resource type ID
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
// Add those filetypes that require extra markup from this template 
// (Currently adds the wrapper <div class="twocol">)
List moreMarkupResourceTypes= Arrays.asList(new Integer[] { 
                                    OpenCms.getResourceManager().getResourceType("person").getTypeId(),
                                    OpenCms.getResourceManager().getResourceType("np_eventcal").getTypeId()
                                });
// Handle case: 
// - the current request URI points to a folder
// - the folder has no title
// - the folder's index file has a title (this is the displayed file, so show that title)
//if (title.isEmpty() && (requestFileUri.endsWith("/") || requestFileUri.endsWith("/index.html"))) {
if (title != null && title.isEmpty()) {
    if (requestFileUri.endsWith("/")) {
        title = cmso.readPropertyObject(requestFileUri.concat("index.html"), "Title", false).getValue("NO TITLE");
    }
}

final String MENU_TOP_URL   = includeFilePrefix + "/header-menu.html";
final String QUICKLINKS_MENU_URI = "/menu-quicklinks.html";
final String LANGUAGE_SWITCH= "/system/modules/no.npolar.common.lang/elements/sibling-switch.jsp";
final String SEARCHBOX      = "/system/modules/no.npolar.site.npweb/elements/search.jsp";
final String LINKLIST       = "../../no.npolar.common.linklist/elements/linklist.jsp";
final String FEED_URL       = cms.link("/" + locale + "/news/newsfeed.xml");
final String HOME_URI       = cms.link("/" + locale + "/");
final boolean EDITABLE_MENU = false;

String menuTemplate = null;
HashMap params = null;
String quickLinksTemplate = null;
HashMap quickLinksParams = null;

String menuFile = cms.property("menu-file", "search");

cms.editable(false);

%><cms:template element="header"><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><%= title %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<%
if (!description.isEmpty())
    out.println("<meta http-equiv=\"description\" content=\"" + description + "\" />");
if (canonical != null) 
    out.println("<link rel=\"canonical\" href=\"" + canonical + "\" />");
// Include css files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_CSS, requestFileUri));
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_HEAD_SNIPPET, requestFileUri));
%><link href="<cms:link>../../no.npolar.common.highslide/resources/js/highslide/highslide.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/sudoslider.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/frame.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/menu.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/npweb.css</cms:link>" rel="stylesheet" type="text/css" />
<!--[if IE]>
<link href="<cms:link>../resources/style/non-standard.css</cms:link>" rel="stylesheet" type="text/css" />
<![endif]-->
<!--[if lte IE 6]>
<link href="<cms:link>../resources/style/old-ie.css</cms:link>" rel="stylesheet" type="text/css" />
<![endif]-->
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.5.0/jquery.min.js"></script>
<%
if (!portal) {
%>
<script type="text/javascript" src="<cms:link>../../no.npolar.common.videoresource/resources/jwplayer/jwplayer.js</cms:link>"></script>
<script type="text/javascript" src="<cms:link>../../no.npolar.common.videoresource/resources/jwplayer/swfobject.js</cms:link>"></script>
<script type="text/javascript" src="<cms:link>../resources/js/commons.js</cms:link>"></script>
<% 
} 
else {
%>
<script type="text/javascript" src="<cms:link>../../no.npolar.common.jquery/resources/jquery.sudoSlider.min.js</cms:link>"></script>
<script type="text/javascript" src="<cms:link>../../no.npolar.site.npweb/resources/js/sudoslider-init.js</cms:link>"></script>
<%
}
// Include javascript files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_JAVASCRIPT, requestFileUri));
%>
<script type="text/javascript" src="<cms:link>../../no.npolar.common.highslide/resources/js/highslide/highslide-settings.js?locale=<%= locale %></cms:link>"></script>
</head>

<body>
    <div id="docwrap">
    <div id="header">
        <div id="header-top">
            <a id="identity" href="<%= HOME_URI %>"></a>
        </div>

        <div id="header-bottom">
            <div class="header-tool-line">
                <%
                /*if (cms.getCmsObject().existsResource(MENU_TOP_URL)) {
                    MenuFactory menuFactory = new MenuFactory(pageContext, request, response);
                    Menu topMenu = menuFactory.createFromXml(MENU_TOP_URL);
                    List topMenuItems = topMenu.getElements();
                    if (!topMenuItems.isEmpty()) {
                        Iterator itr = topMenuItems.iterator();
                        MenuItem mi = null;
                        out.println("<ul class=\"menu\">");
                        while (itr.hasNext()) {
                            mi = (MenuItem)itr.next();
                            out.println("<li>" +
                                            "<a class=\"header-navi\" href=\"" + cms.link(mi.getUrl()) + "\">" +
                                                mi.getNavigationText() +
                                            "</a>" +
                                        "</li>");
                        }
                        out.println("</ul>");
                    }
                }*/
                // Put the path to the menu file in a parameter map
                params = new HashMap();
                params.put("filename", menuFile);
                // Read the property "template-elements" from the menu file. This is the path to the menu template file.
                try {
                    menuTemplate = cms.getCmsObject().readPropertyObject(menuFile, "template-elements", false).getValue();
                } catch (Exception e) {
                    out.println("An error occured while trying to read the template for the menu '" + menuFile + "': " + e.getMessage());
                }
                // Include the "mainmenu" element of the menu template file, pass parameters
                try {
                    //out.println("<div class=\"naviwrap\">");
                    cms.include(menuTemplate, "topmenu", EDITABLE_MENU, params);
                    //out.println("</div>");
                } catch (Exception e) {
                    out.println("An error occured while trying to include the topmenu (using template '" + menuTemplate + "'): " + e.getMessage());
                }
                %>
            </div><!-- .header-tool-line -->
            <div class="header-tool-line">
                <%
                // Include the "breadcrumb" element of the menu template file, pass parameters
                try {
                    cms.include(menuTemplate, "breadcrumb", EDITABLE_MENU, params);
                } catch (Exception e) {
                    out.println("An error occured while trying to include the breadcrumb menu (using template '" + menuTemplate + "'): " + e.getMessage());
                }
                %>
                <div id="global-site-tools">
                    <!-- site search -->
                    <div id="searchbox">
                        <% cms.include(SEARCHBOX); %>
                    </div>
                    <!-- language switch -->
                    <% 
                    Map langParams = new HashMap();
                    langParams.put("text", "false");
                    cms.include(LANGUAGE_SWITCH, null, false, langParams);
                    %>
                </div>
            </div><!-- .header-tool-line -->
            <div class="header-tool-line">
                <%
                // Include the "quicklinks" menu file. It uses its own template file. Pass the URI as a parameter
                try {
                    quickLinksTemplate = cms.getCmsObject().readPropertyObject(QUICKLINKS_MENU_URI, "template-elements", false).getValue();
                    quickLinksParams = new HashMap();
                    quickLinksParams.put("resourceUri", QUICKLINKS_MENU_URI);
                    cms.include(quickLinksTemplate, null, EDITABLE_MENU, quickLinksParams);
                } catch (Exception e) {
                    out.println("An error occured while trying to include the quicklinks menu (using template '" + menuTemplate + "'): " + e.getMessage());
                }
                %>
            </div><!-- .header-tool-line -->
        </div><!-- #header-bottom -->
    </div> <!-- #header -->

    <div id="mainwrap">
        <div id="leftside" class="<%= portal ? "fourcol-equal" : "onecol" %>">
            <%
            // Put the path to the menu file in a parameter map
            // Shouldn't need to - haven't we done that already..?
            /*
            params = new HashMap();
            params.put("filename", menuFile);
            // Read the property "template-elements" from the menu file. This is the path to the menu template file.
            try {
                menuTemplate = cms.getCmsObject().readPropertyObject(menuFile, "template-elements", false).getValue();
            } catch (Exception e) {
                out.println("An error occured while trying to get the the template of menu file '" + menuFile + "': " + e.getMessage());
            }
            */
            // Include the "submenu" element of the menu template file, pass parameters
            try {
                //out.println("<div class=\"naviwrap\">"); // Excessive markup
                cms.include(menuTemplate, "submenu", EDITABLE_MENU, params);
                //out.println("</div>");
            } catch (Exception e) {
                out.println("An error occured while trying to include the submenu (using template '" + menuTemplate + "'): " + e.getMessage());
            }
            %>
        </div><!-- #leftside -->
        
</cms:template>

<cms:template element="contentbody">
	<cms:include element="body" />
</cms:template>

<cms:template element="foot">
        
    </div><!-- #mainwrap -->
    
    <div id="footer">
        <div id="footerlinks">
            <div class="fourcol-equal left">
                <%
                HashMap footerLinksParam = new HashMap();
                footerLinksParam.put("resourceUri", "/footer-1.html");
                cms.include(LINKLIST, "main", false, footerLinksParam);
                %>
            </div>
            <div class="fourcol-equal">
                <%
                footerLinksParam.clear();
                footerLinksParam.put("resourceUri", "/footer-2.html");
                cms.include(LINKLIST, "main", false, footerLinksParam);
                %>
            </div>
            <div class="fourcol-equal">
                <%
                footerLinksParam.clear();
                footerLinksParam.put("resourceUri", "/footer-3.html");
                cms.include(LINKLIST, "main", false, footerLinksParam);
                %>
            </div>
            <div class="fourcol-equal right">
                <%
                footerLinksParam.clear();
                footerLinksParam.put("resourceUri", "/footer-4.html");
                cms.include(LINKLIST, "main", false, footerLinksParam);
                %>
            </div>            
            
        </div>
    </div><!-- #footer -->
    </div><!-- #docwrap -->
<%
boolean includeGoogleAnalytics = !OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
if (includeGoogleAnalytics) { %>
    <!-- Google Analytics -->
    
<%}%>
</body>
</html>
</cms:template>