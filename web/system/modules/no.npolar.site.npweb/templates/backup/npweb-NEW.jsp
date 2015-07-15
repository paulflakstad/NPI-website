<%-- 
    Document   : npweb-NEW
    Created on : Mar 21, 2012, 7:37:59 PM
    Author     : flakstad
--%><%@page import="org.opencms.util.CmsHtmlExtractor"%>
<%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.main.OpenCms,
                org.opencms.xml.content.*,
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
String description          = CmsHtmlExtractor.extractText(cms.property("Description", requestFileUri, ""), "utf-8");
String title                = cms.property("Title", requestFileUri, "");
String feedUri              = cms.property("rss", requestFileUri, "");
boolean portal              = Boolean.valueOf(cms.property("portalpage", requestFileUri, "false")).booleanValue();
String canonical            = null;
String includeFilePrefix    = "";
String fs                   = null; // font size
HttpSession sess            = request.getSession();
String siteName             = cms.label("label.np.sitename");
boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);



// Handle case: canonicalization
// - Priority 1: a canonical URI is specified in the "canonical" property
// - Priority 2: the current request URI is an index file
CmsProperty propCanonical = cmso.readPropertyObject(requestFileUri, "canonical", false);
// First examine the "canonical" property
if (!propCanonical.isNullProperty()) {
    canonical = propCanonical.getValue();
    if (canonical.startsWith("/") && !cmso.existsResource(canonical))
        canonical = null;
}
// If no "canonical" property was found, and we're displaying an index file,
// set the canonical URL to the folder (remove the "index.html" part).
if (canonical == null && CmsRequestUtil.getRequestLink(requestFileUri).endsWith("/index.html")) {
    canonical = cms.link(requestFolderUri);
    // Keep any parameters
    if (!request.getParameterMap().isEmpty()) {
        // Copy the parameter map. (Since we may need to remove some parameters.)
        Map requestParams = new HashMap(request.getParameterMap());
        // Remove internal OpenCms parameters (they start with a double underscore) 
        // and any other unwanted ones - e.g. font size parameters
        Set keys = requestParams.keySet();
        Iterator iKeys = keys.iterator();
        while (iKeys.hasNext()) {
            String key = (String)iKeys.next();
            if (key.startsWith("__") || key.equals("fs")) // This is an internal OpenCms parameter or a font-size parameter ...
                iKeys.remove(); // ... so go ahead and remove it.
        }
        if (!requestParams.isEmpty())
            canonical = CmsRequestUtil.appendParameters(canonical, requestParams, true);
    }
}

if (request.getParameter("__locale") != null) {
    loc = new Locale(request.getParameter("__locale"));
    cms.getRequestContext().setLocale(loc);
}
if (request.getParameter("includeFilePrefix") != null) {
    includeFilePrefix = request.getParameter("includeFilePrefix");
}

if (request.getParameter("fs") != null) {
    fs = request.getParameter("fs");
    if (fs.isEmpty() || fs.length() > 2) {
        fs = null;
    }
    else {
        if (fs.equalsIgnoreCase("M") || fs.equalsIgnoreCase("L") || fs.equalsIgnoreCase("XL")) // Limit to these values
            sess.setAttribute("fs", fs);
    }
}

// Get the request file's resource type ID
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
if (!portal) {
    if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId())
        portal = true;
}
// Add those filetypes that require extra markup from this template 
// (Currently adds the wrapper <div class="twocol">)
List moreMarkupResourceTypes= Arrays.asList(new Integer[] { 
                                    //OpenCms.getResourceManager().getResourceType("person").getTypeId(),
                                    //OpenCms.getResourceManager().getResourceType("np_eventcal").getTypeId(),
                                    OpenCms.getResourceManager().getResourceType("np_event").getTypeId(),
                                    OpenCms.getResourceManager().getResourceType("gallery").getTypeId(),
                                    OpenCms.getResourceManager().getResourceType("faq").getTypeId()
                                });
// Handle case:
// - the current request URI is a resource of type "person" AND
// - the resource has a title on the format "lastname, firstname"
if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("person").getTypeId()) {
    if (title != null && !title.isEmpty() && title.indexOf(",") > -1) {
        String[] titleParts = title.split(","); // [Flakstad][ Paul-Inge]
        if (titleParts.length == 2) {
            title = titleParts[1].trim() + " " + titleParts[0].trim();
        }
    }
}

// Handle case: 
// - the current request URI points to a folder
// - the folder has no title
// - the folder's index file has a title (this is the displayed file, so show that title)
//if (title.isEmpty() && (requestFileUri.endsWith("/") || requestFileUri.endsWith("/index.html"))) {
if (title != null && title.isEmpty()) {
    if (requestFileUri.endsWith("/")) {
        title = cmso.readPropertyObject(requestFileUri.concat("index.html"), "Title", false).getValue("No title");
    }
}
if (!title.equals(siteName)) {
    title = title.concat(" - ").concat(siteName);
}

final String MENU_TOP_URL       = includeFilePrefix + "/header-menu.html";
final String QUICKLINKS_MENU_URI= "/menu-quicklinks.html";
final String LANGUAGE_SWITCH    = "/system/modules/no.npolar.common.lang/elements/sibling-switch.jsp";
final String FONT_SIZE_SWITCH   = "/system/modules/no.npolar.site.npweb/elements/font-size-switch.jsp";
final String FOOTERLINKS        = "/system/modules/no.npolar.site.npweb/elements/footerlinks.jsp";
final String SEARCHBOX          = "/system/modules/no.npolar.site.npweb/elements/search.jsp";
final String LINKLIST           = "../../no.npolar.common.linklist/elements/linklist.jsp";
final String HOME_URI           = cms.link("/" + locale + "/");
final boolean EDITABLE_MENU     = true;

String menuTemplate = null;
HashMap params = null;
String quickLinksTemplate = null;
HashMap quickLinksParams = null;

String menuFile = cms.property("menu-file", "search");

cms.editable(false);
//
// TODO: ADD NEWS RSS TO TEMPLATE!! USE A PROPERTY TO DO THIS.
//
%><cms:template element="header"><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="<%= loc.getLanguage() %>" xml:lang="<%= loc.getLanguage() %>">
<head>
<title><%= title %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Language" content="<%= loc.getLanguage() %>"/>
<link rel="icon" type="image/png" href="/favicon.png" />
<link href="<cms:link>../resources/fonts/MyFontsWebfontsKit.css</cms:link>" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js"></script>
<script type="text/javascript" src="<cms:link>../resources/js/highslide/highslide-full.js</cms:link>"></script>
<%
if (!description.isEmpty())
    out.println("<meta http-equiv=\"description\" content=\"" + description + "\" />");
// If a font size parameter was set, add an additional safety measure to prevent this URL from being indexed.
if (fs != null) {
    out.println("<meta name=\"robots\" content=\"noindex\" />");
}
if (canonical != null) 
    out.println("<link rel=\"canonical\" href=\"" + canonical + "\" />");
if (!feedUri.isEmpty()) {
    out.println("<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"" + cms.link(feedUri) + "\" />");
}
// Include css files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_CSS, requestFileUri));
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_HEAD_SNIPPET, requestFileUri));
%><link href="<cms:link>../../no.npolar.common.highslide/resources/js/highslide/highslide.css</cms:link>" rel="stylesheet" type="text/css" />
<!--<link href="<cms:link>../resources/style/sudoslider.css</cms:link>" rel="stylesheet" type="text/css" />-->
<link href="<cms:link>../resources/style/frame.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/menu.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/npweb.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/npweb-portalpage-mods-2012-02-08.css</cms:link>" rel="stylesheet" type="text/css" />
<link href="<cms:link>../resources/style/menu-dropdown.css</cms:link>" rel="stylesheet" type="text/css" />
<!--[if lte IE 8]>
<link href="<cms:link>../resources/style/ie8.css</cms:link>" rel="stylesheet" type="text/css" />
<![endif]-->
<!--[if lte IE 7]>
<link href="<cms:link>../resources/style/ie7.css</cms:link>" rel="stylesheet" type="text/css" />
<![endif]-->
<!--[if lte IE 6]>
<link href="<cms:link>../resources/style/old-ie.css</cms:link>" rel="stylesheet" type="text/css" />
<![endif]-->
<link href="<cms:link>../resources/style/npweb-portalpage-mods-2012-02-15-audun.css</cms:link>" rel="stylesheet" type="text/css" />
<%
// Include the WAI stylesheet if neccessary
if (sess.getAttribute("fs") != null && !((String)sess.getAttribute("fs")).equalsIgnoreCase("m")) {
%>
<link href="<cms:link>../resources/style/wai.css</cms:link>" rel="stylesheet" type="text/css" />
<%
}
%>
<script type="text/javascript" src="<cms:link>../../no.npolar.common.jquery/resources/jquery.form-defaults.js</cms:link>"></script> 
<script type="text/javascript" src="<cms:link>../../no.npolar.common.jquery/resources/jquery.autofill.min.js</cms:link>"></script> 
<script type="text/javascript" src="<cms:link>../resources/js/jquery.hoverintent.min.js</cms:link>"></script>
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
<script type="text/javascript" src="<cms:link>../../no.npolar.site.npweb/resources/js/sudoslider-init-2012-03-28.js</cms:link>"></script>
<%
}
// Include javascript files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_JAVASCRIPT, requestFileUri));
%>
<script type="text/javascript" src="<cms:link>../../no.npolar.common.highslide/resources/js/highslide/highslide-settings.js?locale=<%= locale %></cms:link>"></script>
<%
if (!loggedInUser) { %>
    <!-- Google Analytics -->
    <script type="text/javascript">
      var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-770196-22']);//UA-770196-21
      _gaq.push(['_trackPageview']);
      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();
    </script>
<%}%>

<script type="text/javascript">
/*<![CDATA[*/
window.onresize = function() {
    // Get all sub-menus
    var submenus = $("#nav_topmenu li").find("ul");
    // Reposition each sub-menu
    $.each(submenus, function() {
            //$(this).fadeIn(1); // Assume the menu has been faded out, fade it in (can't reposition hidden elements)
            reposition(this);
            //$(this).fadeOut(1); // Fade it out again
        }
    );
}



var originalWinWidth = $(window).width();
var winWidth = originalWinWidth;

function reposition(element) {
    var pxRight = $(window).width() - ($(element).offset().left + $(element).width());
    var offset = 2;
    if (pxRight < 0) {
        if ($(element).hasClass("snap-right")) {
            //$(element).css("left", (-1 * $(element).width() + 10));
            $(element).css("left", (-1 * $(element).width() + offset));
        }
        else {
            //$(element).css("margin-left", pxRight - 10);
            $(element).css("margin-left", pxRight - offset);
        }
    } 
    else {
        if ($(element).hasClass("snap-right")) {
            //$(element).css("left", $(element).width() - 10);
            $(element).css("left", $(element).width() - offset);
        }
        else {
            $(element).css("margin-left", "");
        }
    }
}

function showSubMenu(parentMenuItem) {
    var subMenu = $(parentMenuItem).next("ul");
    var clipped = $(window).width() - (subMenu.offset().left + subMenu.width()) < 0;
    if (clipped) {
        reposition(subMenu);
    }
}
/*]]>*/
</script>
</head>

<body>
    <div id="header" class="<%= locale %>">
        <div id="header-top">
            <%
            // Include the "quicklinks" menu file. It uses its own template file. Pass the URI as a parameter
            try {
                quickLinksTemplate = cms.getCmsObject().readPropertyObject(QUICKLINKS_MENU_URI, "template-elements", false).getValue();
                quickLinksParams = new HashMap();
                quickLinksParams.put("resourceUri", QUICKLINKS_MENU_URI);
                cms.include(quickLinksTemplate, null, EDITABLE_MENU, quickLinksParams);
            } catch (Exception e) {
                out.println("<!-- An error occured while trying to include the quicklinks menu (using template '" + quickLinksTemplate + "'): " + e.getMessage() + " -->");
            }
            %>
            
            <div id="header-mid">
                <div class="fullwidth-centered">
                    <div id="global-site-tools">
                        <!-- site search -->
                        <div id="searchbox" class="global-site-tool">
                            <% cms.include(SEARCHBOX); %>
                        </div>
                        <!-- font size and language selectors -->   
                        <div id="lang-switch" class="global-site-tool">
                            <%
                            Map langParams = new HashMap();
                            langParams.put("text", "false");
                            cms.include(LANGUAGE_SWITCH, null, false, langParams);
                            %>
                        </div>                 
                        <div id="fs-switch" class="global-site-tool">
                            <% cms.include(FONT_SIZE_SWITCH); %>
                        </div>
                    </div>
            
                    <a id="identity" href="<%= HOME_URI %>"></a>
                </div><!-- .fullwidth-centered -->
            </div><!-- #header-mid -->
        </div><!-- #header-top -->

        <div id="header-bottom">
            <div id="nav_sticky">
                <div id="nav_top_wrap">
                    <%
                    // Put the path to the menu file in a parameter map
                    params = new HashMap();
                    params.put("filename", menuFile);
                    // Read the property "template-elements" from the menu file. This is the path to the menu template file.
                    try {
                        menuTemplate = cms.getCmsObject().readPropertyObject(menuFile, "template-elements", false).getValue();
                    } catch (Exception e) {
                        out.println("<!-- An error occured while trying to read the template for the menu '" + menuFile + "': " + e.getMessage() + " -->");
                    }
                    // Include the "mainmenu" element of the menu template file, pass parameters
                    try {
                        //out.println("<div class=\"naviwrap\">");
                        cms.include(menuTemplate, "topmenu-dd", EDITABLE_MENU, params);
                        //out.println("</div>");
                    } catch (Exception e) {
                        out.println("<!-- An error occured while trying to include the topmenu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
                    }
                    %>
                </div><!-- #nav_top_wrap -->
                
                
                <div id="nav_breadcrumb_wrap">
	            <%
                    // Include the "breadcrumb" element of the menu template file, pass parameters
                    try {
                        cms.include(menuTemplate, "breadcrumb", EDITABLE_MENU, params);
                    } catch (Exception e) {
                        out.println("<!-- An error occured while trying to include the breadcrumb menu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
                    }
                    %>
                </div>
            </div><!-- #nav_sticky -->
        </div><!-- #header-bottom -->
    </div> <!-- #header -->
    <div id="docwrap">
    <div id="mainwrap">
        <%
        if (!portal) {
            out.println("<div id=\"leftside\" class=\"" + (portal ? "fourcol-equal" : "onecol") + "\">");
            
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
                out.println("<!-- An error occured while trying to include the submenu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
            }
            
            out.println("</div><!-- #leftside -->");
            
            out.println("<div id=\"content\">");

            if (moreMarkupResourceTypes.contains(requestFileTypeId)) {
                out.println("<div class=\"twocol\">");
            }
        }
                    
        if (locale.equalsIgnoreCase("en")) {
            CmsResource requestFileResource = cmso.readResource(requestFileUri);
            if (!requestFileResource.isFolder()) {
                CmsFile requestFile = cmso.readFile(requestFileResource);
                // build up the xml content instance
                CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, requestFile);
                if (!xmlContent.hasLocale(loc)) {
                    List siblings = cmso.readSiblings(requestFileUri, CmsResourceFilter.DEFAULT);
                    Iterator iSiblings = siblings.iterator();
                    String norwegianPath = null;
                    while (iSiblings.hasNext()) {
                        CmsResource sibling = (CmsResource)iSiblings.next();
                        if (cmso.readPropertyObject(sibling, "locale", true).getValue("").equals("no")) {
                            norwegianPath = cmso.getSitePath(sibling);
                            break;
                        }
                    }

                    out.println("<div class=\"twocol\">");
                    out.println("<h1>This page has not yet been translated</h1>");
                    out.println("<div class=\"ingress\">We're sorry, this page does not exist in English yet. Please check back at a later time.</div>");
                    if (norwegianPath != null) {
                        out.println("<div class=\"paragraph\">");
                        out.println("<ul><li><a href=\"" + cms.link(norwegianPath) + "\">View this page in Norwegian</a></li></ul>");
                        out.println("</div>");
                    }
                    out.println("</div>");
                }
            }
        }
        %>
</cms:template>

<cms:template element="contentbody">
	<cms:include element="body" />
</cms:template>

<cms:template element="footer">
            <%
            if (!portal) {
                if (moreMarkupResourceTypes.contains(requestFileTypeId)) {
                    out.println("</div><!-- .twocol -->");
                }
                out.println("</div><!-- #content -->");
            }
            %>
    </div><!-- #mainwrap -->
    
    <div id="footer">
        <div id="footerlinks">
            <% cms.include(FOOTERLINKS); %>
        </div>
    </div><!-- #footer -->
    </div><!-- #docwrap -->
<script type="text/javascript">
/*<![CDATA[*/

// Get some initial values - we'll use them as reset values
var dropdownTop = $("#nav_topmenu li ul").css("top");
var docwrapTopPadding = $("#docwrap").css("padding-top");

function moveScroller() {
    /* // Alternative 1
            var stickyHeight = $("#header").height();
            $("#header").css({position:"fixed", "z-index":"9999", left:"0"});
            $("#docwrap").css({"padding-top":(stickyHeight+10)+"px"});
      //$(window).scroll(a);a()
    }
    //*/

    //* // Alternative 2
    var stickNavigation = function() {
        var pxAboveFold = $(window).scrollTop(); // The number of pixels hidden from view on top when scrolling a page
        var pxAboveNav = $("#nav_sticky").offset().top; // The number of pixels above the HTML element, including pixels hidden from view (e.g. 90)
        var stickyHeight = $("#nav_sticky").height(); // The height of the sticky element
        var navBarHeight = $("#nav_topmenu").height();
        var topHeaderHeight = $("#header-top").height();
        var extraTopPadding = 13;

        if (pxAboveFold > pxAboveNav) {
            // If the sticky element is not "stuck" ...
            if ($("#nav_sticky").css("position") != "fixed") {
                // ... "stick" it
                $("#nav_sticky").css({
                                        "position":"fixed"
                                        , "top":"0"
                                        , "width":"100%"
                                        , "z-index":"999"
                                    }); 
                // Add some top padding to the content following the sticky element, 
                // so that it will display below the sticky element, not behind it
                $("#docwrap").css({"padding-top":(stickyHeight+extraTopPadding)+"px"});
                // Position the first dropdown menu at the bottom of the main navigation bar
                $("#nav_topmenu > li > ul").css({"top":navBarHeight+"px"});
            }
        } 
        else {
            if (pxAboveFold < topHeaderHeight) {                
                // ... "unstick" it (reset values)
                $("#nav_sticky").css({
                                        "position":"static"
                                        , "z-index":"1"
                                        , "width":"auto"
                                    });
                // Reset the padding of the content following the sticky element
                $("#docwrap").css({"padding-top":docwrapTopPadding});
                // Position the first dropdown menu at the bottom of the main navigation bar
                $("#nav_topmenu > li > ul").css({"top":dropdownTop});
            }
        }
    };
    $(window).scroll(stickNavigation);
}

moveScroller();
	
//
// Fade in sub-menus (the drop-downs)
//
//*// Comment out this section for IE
// Set all submenus to "display=block" and fade them out - this way we can use fadeIn() on hover.
//$("#nav_topmenu li").find("ul").css("display", "block").fadeOut(1);
// Set all submenus to "display=block" and hide them - this way we can use fadeIn() on hover.
$("#nav_topmenu li").find("ul").css("display", "block").hide();

/**
* Fades in a sub-menu
**/
function fadeInSubMenu() {
	// Find "the sub-menu for the menu item we're currently hovering over"
	var submenu = $(this).find("ul").first();
        // Dim all siblings of parent navigation items (messes up IE => outcommented)
	//submenu.parent("li").siblings("li").fadeTo(100, 0.6);
	
	// Begin "bug" fix: First time sub-menu is displayed, it is not repositioned to fit inside viewport. Only on from the second time and on, it is positioned correctly.
	// (To see the bug, uncomment the bug-fix, load a page in full-screen, then resize the browser so the menus are rendered at least partially off-screen.)
	$(submenu).show();
	reposition(submenu);
	$(submenu).hide();
	// End "bug" fix
	
	// Show the sub-menu
	$(submenu).fadeIn(100);
}

/**
* Fades out a sub-menu
**/
function fadeOutSubMenu() {
	// Find "the sub-menu for the menu item we're currently hovering over"
	var submenu = $(this).find("ul").first();
	// Hide the sub-menu
	$(submenu).fadeOut(100);
	
	// Begin "bug" fix: First time a sub-menu is displayed, it is not repositioned to fit inside viewport. Only on from the second time and on, it is positioned correctly.
	// (To see the bug, uncomment the bug-fix, load a page in full-screen, then resize the browser so the menus are rendered at least partially off-screen.)
	$(submenu).show();
	reposition(submenu);
	$(submenu).hide();
	// End "bug" fix
}

//*
//
// ALTERNATIVE 1: hoverIntent() - Use slight delays when showing/hiding submenus
//
// Use the hoverIntent plugin instead of jQuery's native hover() function 
// (This way, we can add some delays for usability purposes)
var config = {
	over: fadeInSubMenu, // The function to call onMouseOver
	//timeout: 600, // The delay, in milliseconds, before the "out" function is called
	//interval: 150, // The interval between checking mouse position (the soonest "over" function can be called is after a single interval)
        timeout:500,
        interval:250,
	out: fadeOutSubMenu // The function to call onMouseOut
}

// Add the "hover listener" by passing the configuration object to hoverIntent
$("#nav_topmenu li").hover( function() { $(this).toggleClass("inpath"); } ).hoverIntent(config);
// Remove dimming on all siblings of parent navigation items (messes up IE => outcommented)
//$("#nav_topmenu li").mouseleave( function() { $(this).find("ul").first().parent("li").siblings("li").fadeTo(1, 1); } );
// END ALTERNATIVE 1
//*/


/*
//
// ALTERNATIVE 2: hover() - No delays, show/hide submenus done immediately upon hover
//
$("#nav_topmenu li").hover(fadeInSubMenu, fadeOutSubMenu);
// END ALTERNATIVE 2
//*/
    
/*]]>*/
</script>
</body>
</html>
</cms:template>