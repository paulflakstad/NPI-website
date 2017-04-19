<%-- 
    Document   : npi-public-site
    Created on : Aug 22, 2016, 10:18:47 AM
    Author     : Paul-Inge Flakstad, Norwegian Polar Institute <flakstad at npolar.no>
--%><%@page import="org.opencms.jsp.*"%>
<%@page import="org.opencms.file.types.*"%>
<%@page import="org.opencms.file.*"%>
<%@page import="org.opencms.mail.CmsSimpleMail"%>
<%@page import="org.opencms.util.CmsStringUtil"%>
<%@page import="org.opencms.util.CmsHtmlExtractor"%>
<%@page import="org.opencms.util.CmsRequestUtil"%>
<%@page import="org.opencms.security.CmsRoleManager"%>
<%@page import="org.opencms.security.CmsRole"%>
<%@page import="org.opencms.main.OpenCms"%>
<%@page import="org.opencms.xml.content.*"%>
<%@page import="org.opencms.db.CmsResourceState"%>
<%@page import="org.opencms.flex.CmsFlexController"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="java.net.URLDecoder"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.text.DateFormat"%>
<%@page import="no.npolar.common.menu.*"%>
<%@page import="no.npolar.util.CmsAgent"%>
<%@page import="no.npolar.util.contentnotation.*"%>
<%@page trimDirectiveWhitespaces="true" pageEncoding="UTF-8" session="true" %>
<%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"%>
<%!
/**
 * Gets a date in the datetime attribute format.
 */
private String getDateAsDatetimeAttribute(Date date) {
    SimpleDateFormat dfFullIso = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", new Locale("en"));
    dfFullIso.setTimeZone(TimeZone.getTimeZone("GMT+1"));
    return dfFullIso.format(date);
}
public String getAltLangLink(CmsJspActionElement cms, 
                            String altResourcePath, 
                            String queryString, 
                            Locale altLocale, 
                            String switchLabel) {

    String s = "<a"
                + " href=\"" + cms.link(altResourcePath).concat(queryString) + "\""
                + " data-tooltip=\"" + OpenCms.getWorkplaceManager().getMessages(altLocale).key("label.language.switch") + "\""
                + " class=\"button language-switch language-switch--" + altLocale + "\""
                + ">"
                    //+ "<span class=\"language-switch-flag language-switch__flag\"></span>";
                    + "<svg class=\"icon icon-cogwheel\"><use xlink:href=\"#icon-cogwheel\"></use></svg>";

    if (switchLabel != null && !switchLabel.isEmpty()) {
        s += "<span class=\"language-switch__language\"> " +
                        switchLabel.substring(0,1).toUpperCase() + switchLabel.substring(1) +
                        "</span>";
    }
    
    s += "</a>";

    return s;
}
%>
<%
CmsAgent cms = new CmsAgent(pageContext, request, response);
CmsObject cmso = cms.getCmsObject();
String requestFileUri = cms.getRequestContext().getUri();
String requestFolderUri = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId = cmso.readResource(requestFileUri).getTypeId();
Locale locale = cms.getRequestContext().getLocale();
String loc = locale.toString();

final boolean USER_LOGGED_IN = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

final String ONLINE_SCHEME  = "http";
final String ONLINE_DOMAIN  = "www.npolar.no";

final String PROP_REDIR_PERM = "redirect.permanent";
final String PROP_TITLE = CmsPropertyDefinition.PROPERTY_TITLE;
final String PROP_TITLE_ADDON = CmsPropertyDefinition.PROPERTY_TITLE.concat(".addon");
final String PROP_CANONICAL_URI = "canonical";
final String PROP_DESCR = CmsPropertyDefinition.PROPERTY_DESCRIPTION;
final String PROP_FEATURED_IMAGE_URI = "image.thumb";
final String PROP_RSS_URI = "rss";
final String PROP_SITE_NAME = "sitename";
final String PROP_MENU_FILE_URI = "menu-file";
final String PROP_PORTAL_PAGE = "portalpage";
final String PROP_HEAD_SNIPPET = "head.snippet";
final String PROP_ALT_LANG_LINK_EXCLUDE = "language-switch.exclude";

final String RES_TYPE_PORTAL_PAGE = "np_portalpage";
final String RES_TYPE_EVENT = "np_event";
final String RES_TYPE_IMAGE_GALLERY = "gallery";
final String RES_TYPE_FORM = "np_form";
final String RES_TYPE_FAQ = "faq";
final String RES_TYPE_NEWS_ARTICLE = "newsbulletin";
final String RES_TYPE_PERSON = "person";
final String RES_TYPE_EVENT_CALENDAR = "np_eventcal";

final String REQUEST_ATTR_TITLE = "title";
final String REQUEST_ATTR_ALT_LANG_URI = "alternate_uri";

final String TITLE_ADDON_VALUE_NONE = "none";

final String ENCODING = "UTF-8";

// Redirect HTTPS requests to HTTP for any non-logged in user
if (!USER_LOGGED_IN && cms.getRequest().isSecure()) {
    String redirAbsPath = ONLINE_SCHEME + "://" + request.getServerName() + cms.link(requestFileUri);
    String qs = cms.getRequest().getQueryString();
    if (qs != null && !qs.isEmpty()) {
        redirAbsPath += "?" + qs;
    }
    //out.println("<!-- redirect path is '" + redirAbsPath + "' -->");
    //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
    cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
    return;
}

// Prevent exposing backend/alternative domain names
if (!USER_LOGGED_IN && !request.getServerName().equals(ONLINE_DOMAIN)) {
    String redirAbsPath = ONLINE_SCHEME + "://" + ONLINE_DOMAIN + cms.link(requestFileUri);
    String qs = cms.getRequest().getQueryString();
    if (qs != null && !qs.isEmpty()) {
        redirAbsPath += "?" + qs;
    }
    //out.println("<!-- redirect path is '" + redirAbsPath + "' -->");
    //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
    cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
    return;
}

// #############################################################################
//  Redirect somewhere?
// -----------------------------------------------------------------------------
//
// This is used for example on Norwegian siblings of events with content in 
// English only. We use it so that the event can appear also in listings on the
// Norwegian section (because a Norwegian sibling exists), but at the same time
// only the English version will ever be accessible (because the Norwegian 
// version redirects to it).
//
// This redirect option can help handling event navigation and registration
// forms (if such pages exists), and it is also good for SEO (because there will  
// be no duplicate content).
//
// It also helps meet Norwegian accessibility requirements.
//
// IMPORTANT: Setting this property carelessly or incorrectly can cause A LOT of 
// damage to the site. USE WITH CARE!
// -----------------------------------------------------------------------------
CmsProperty redirPermProp = cmso.readPropertyObject(requestFileUri, PROP_REDIR_PERM, true);
if (!redirPermProp.isNullProperty()) {
    String redirPermPath = redirPermProp.getValue("");
    
    if (cmso.existsResource(redirPermPath)) { // Don't redirect to non-existing resources
        String redirAbsPath = request.getScheme() + "://" + request.getServerName() + cms.link(redirPermPath);
        String qs = cms.getRequest().getQueryString();
        if (qs != null && !qs.isEmpty()) {
            redirAbsPath += "?" + qs;
        }
        //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
        cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
        return;
    } else {
        try {
            // Attempt to redirect to non-existing resource: Send error message.
            CmsSimpleMail errorMail = new CmsSimpleMail();
            errorMail.addTo("web@npolar.no");
            errorMail.setFrom("no-reply@npolar.no");
            errorMail.setSubject("Error on NPI website");
            errorMail.setMsg("The resource " + OpenCms.getLinkManager().getOnlineLink(cmso, requestFileUri) 
                    + " attempted to permanently redirect to " + OpenCms.getLinkManager().getOnlineLink(cmso, redirPermPath) 
                    + ", which does not exist. Please fix this ASAP.");
            errorMail.send();
        } catch (Exception e) {

        }
    }
}

//Locale locale                  = cms.getRequestContext().getLocale();
//String loc               = locale.toString();
String description          = CmsStringUtil.escapeHtml(CmsHtmlExtractor.extractText(cms.property(PROP_DESCR, requestFileUri, ""), ENCODING));
String title                = cms.property(PROP_TITLE, requestFileUri, "");
String titleAddOn           = cms.property(PROP_TITLE_ADDON, "search", "");
String feedUri              = cms.property(PROP_RSS_URI, requestFileUri, "");
boolean portal              = Boolean.valueOf(cms.property(PROP_PORTAL_PAGE, requestFileUri, "false")).booleanValue();
String canonical            = null;
String featuredImage        = null;
//String includeFilePrefix    = "";
HttpSession sess            = request.getSession();
String siteName             = cms.property(PROP_SITE_NAME, "search", cms.label("label.np.sitename"));
//boolean pinnedNav           = false; 
boolean homePage            = false;
//try { pinnedNav             = Boolean.parseBoolean((String)sess.getAttribute("pinned_nav")); } catch (Exception e) {  }




Date dr = null;
String drStr = null;
try {
    long drLong = cmso.readResource(requestFileUri).getDateReleased();
    dr = drLong > 0 ? new Date(drLong) : null;
    drStr = new SimpleDateFormat(cms.label("label.np.dateformat.normal"), locale).format(dr);
} catch (Exception e) {
    // No "date released" attribute
}

/*
// Set "Last-Modified" and "Expires" headers
try {
    // Get the request file's type
    int requestFileType = cmso.readResource(requestFileUri).getTypeId();
    // Is the request file dynamically generated?
    boolean isDynGen = requestFileType == OpenCms.getResourceManager().getResourceType("gallery").getTypeId()
                        || requestFileType == OpenCms.getResourceManager().getResourceType("person").getTypeId()
                        || requestFileType == OpenCms.getResourceManager().getResourceType("resourcelist").getTypeId()
                        || requestFileType == OpenCms.getResourceManager().getResourceType("newslist").getTypeId()
                        || requestFileType == OpenCms.getResourceManager().getResourceType("np_portalpage ").getTypeId()
                        || requestFileType == OpenCms.getResourceManager().getResourceType("np_species ").getTypeId();
    // Date format: Wed, 15 Nov 1995 04:58:08 GMT
    //DateFormat gmtFormat = new SimpleDateFormat("EEE, dd MM yyyy HH:mm:ss z", new Locale("en"));
    //gmtFormat.setTimeZone(TimeZone.getTimeZone("GMT"));
    long maxAge = isDynGen ? 1000 * 60 : 1000 * 60 * 60 * 24 * 7; // 60 secs : 1 week
    long lastModLong = isDynGen ? System.currentTimeMillis() : cmso.readResource(requestFileUri).getDateLastModified();
    long expiresLong = System.currentTimeMillis() + maxAge;
    CmsFlexController.getController(request).setDateExpiresHeader(cms.getResponse(), expiresLong, maxAge);
    CmsFlexController.getController(request).setDateLastModifiedHeader(cms.getResponse(), lastModLong);
    if (isDynGen)
        CmsFlexController.getController(request).getTopResponse().setHeader("Pragma", "no-cache");
} catch (Exception e) {
    
}
*/

// Enable session-stored "hover box" resolver
ContentNotationResolver cnr = new ContentNotationResolver();
try {
    // Load global notations
    cnr.loadGlobals(cms, "/" + loc + "/_global/tooltips.html");
    cnr.loadGlobals(cms, "/" + loc + "/_global/references.html");
    sess.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
} catch (Exception e) {
    out.println("<!-- Content notation resolver error: " + e.getMessage() + " -->");
}

homePage = requestFileUri.equals("/" + locale + "/") 
            || requestFileUri.equals("/" + locale + "/index.html")
            || requestFileUri.equals("/" + locale + "/index.jsp");




// Handle case: canonicalization
// - Priority 1: a canonical URI is specified in the "canonical" property
// - Priority 2: the current request URI is an index file
CmsProperty propCanonical = cmso.readPropertyObject(requestFileUri, PROP_CANONICAL_URI, false);
// First examine the "canonical" property
if (!propCanonical.isNullProperty()) {
    canonical = propCanonical.getValue();
    if (canonical.startsWith("/")) {
        if (!cmso.existsResource(canonical)) {
            canonical = null;
        }
    }
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
            if (key.startsWith("__")) // This is an internal OpenCms parameter or a font-size parameter ...
                iKeys.remove(); // ... so go ahead and remove it.
        }
        if (!requestParams.isEmpty())
            canonical = CmsRequestUtil.appendParameters(canonical, requestParams, true);
    }
}
// Convert relative URI to absolute URL
if (canonical != null && canonical.startsWith("/")) {
    canonical = OpenCms.getLinkManager().getOnlineLink(cmso, canonical);
}

if (request.getParameter("__locale") != null) {
    locale = new Locale(request.getParameter("__locale"));
    cms.getRequestContext().setLocale(locale);
}
/*
if (request.getParameter("includeFilePrefix") != null) {
    includeFilePrefix = request.getParameter("includeFilePrefix");
}
//*/
if (!portal) {
    try {
        if (requestFileTypeId == OpenCms.getResourceManager().getResourceType(RES_TYPE_PORTAL_PAGE).getTypeId())
            portal = true;
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Portal page module not installed
    }
}

String[] moreMarkupResourceTypeNames = {
                                            RES_TYPE_EVENT
                                            , RES_TYPE_IMAGE_GALLERY
                                            , RES_TYPE_FORM
                                            , RES_TYPE_FAQ
                                            //, RES_TYPE_PERSON
                                            //, RES_TYPE_EVENT_CALENDAR
                                        };
// Add those filetypes that require extra markup from this template 
// (These will be wrapped in <article class="main-content">)
List<Integer> moreMarkupResourceTypes= new ArrayList();
for (int iResTypeNames = 0; iResTypeNames < moreMarkupResourceTypeNames.length; iResTypeNames++) {
    try {
        moreMarkupResourceTypes.add(OpenCms.getResourceManager().getResourceType(moreMarkupResourceTypeNames[iResTypeNames]).getTypeId());
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Resource type not installed
    }
}

// Handle case:
// - Title set as request attribute
if (request.getAttribute(REQUEST_ATTR_TITLE) != null) {
    try {
        String reqAttrTitle = (String)request.getAttribute(REQUEST_ATTR_TITLE);
        //out.println("<!-- setting title to '" + reqAttrTitle + "' (found request attribute) -->");
        if (!reqAttrTitle.isEmpty()) {
            title = reqAttrTitle;
        }
    } catch (Exception e) {
        // The title found as request attribute was not of type String
    }
}


// Handle case:
// - the current request URI is a resource of type "person" AND
// - the resource has a title on the format "lastname, firstname"
try {
    if (requestFileTypeId == OpenCms.getResourceManager().getResourceType(RES_TYPE_PERSON).getTypeId()) {
        if (title != null && !title.isEmpty() && title.indexOf(",") > -1) {
            String[] titleParts = title.split(","); // [Flakstad][ Paul-Inge]
            if (titleParts.length == 2) {
                title = titleParts[1].trim() + " " + titleParts[0].trim();
            }
        }
    }
} catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
    // Resource type "person" not installed
}

// Handle case: 
// - the current request URI points to a folder
// - the folder has no title
// - the folder's index file has a title (this is the displayed file, so show that title)
//if (title.isEmpty() && (requestFileUri.endsWith("/") || requestFileUri.endsWith("/index.html"))) {
if (title != null && title.isEmpty()) {
    if (requestFileUri.endsWith("/")) {
        title = cmso.readPropertyObject(requestFileUri.concat("index.html"), PROP_TITLE, false).getValue("No title");
    }
}

// Insert the "add-on" to the title. For example: A big event has multiple
// pages, and to make the titles unique, the event name could be used as a title add-on.
// Instead of "Programme - NPI", the title would be "Programme - <event name> - NPI"
if (titleAddOn != null && !titleAddOn.equalsIgnoreCase(TITLE_ADDON_VALUE_NONE) && !titleAddOn.isEmpty()) {
    title = title.concat(" - ").concat(titleAddOn);
}

// Append site name to title OR replace title with site name (home pages only)
if (!homePage) {
    title = title.concat(" - ").concat(siteName);
} else {
    title = siteName;
}

title = CmsHtmlExtractor.extractText(title, ENCODING);

// Done with the title. Now create a version of the title specifically targeted at social media (facebook, twitter etc.)
String socialMediaTitle = title.endsWith((" - ").concat(siteName)) ? title.replace((" - ").concat(siteName), "") : title;
// Featured image set? (Also for social media.)
featuredImage = cmso.readPropertyObject(requestFileUri, PROP_FEATURED_IMAGE_URI, false).getValue(null);

//final String MENU_TOP_URL       = includeFilePrefix + "/header-menu.html";
final String QUICKLINKS_MENU_URI= "/menu-quicklinks.html";
final String LANGUAGE_SWITCH    = "/system/modules/no.npolar.common.lang/elements/sibling-switch.jsp";
final String FOOTER_CONTENT     = "/" + loc + "/footer-content.txt"; //"/system/modules/no.npolar.site.npweb/elements/footerlinks.jsp";
final String SERP_URI           = cms.link("/" + loc + "/" + (loc.equalsIgnoreCase("no") ? "sok" : "search") + ".html");
//final String LINKLIST           = "../../no.npolar.common.linklist/elements/linklist.jsp";
final String HOME_URI           = cms.link("/" + loc + "/");
final String SITE_LOGO_URI      = "/system/modules/no.npolar.site.npweb/resources/style/np-logo.svg";
final String IMAGE_GALLERY_HEAD_SNIPPET = "/system/modules/no.npolar.common.gallery/resources/head-snippet.jsp";
final boolean EDITABLE_MENU     = true;

final String LABEL_MENU_HIDE    = loc.equalsIgnoreCase("no") ? "Skjul meny" : "Hide menu";

String menuTemplate = null;
HashMap params = null;
String quickLinksTemplate = null;
HashMap quickLinksParams = null;

String menuFile = cms.property(PROP_MENU_FILE_URI, "search");

boolean pageHasImageGallery = false;
try { 
    List<String> elNames = CmsXmlContentFactory.unmarshal(cmso, cmso.readFile(requestFileUri)).getNames(locale);
    for (String elName : elNames) {
        //out.println("<!-- " + elName + " : " + elName.matches("(^|((.*)/))EmbeddedGallery\\[\\d\\](.*)$") + " -->");
        if (elName.matches("(^|((.*)/))EmbeddedGallery\\[\\d\\](.*)$")) {
            pageHasImageGallery = true;
            break;
        }
    }
} catch (Exception e) {}

// We do not want to enable direct edit
cms.editable(false);

// -----------------------------------------------------------------------------
// ToDo:
// 
// - Add <link rel="alternate" ...> on pages with multiple language variants
// - Move font loading to bottom (?) (Near </body>)

%><cms:template element="header"><!DOCTYPE html>
<html lang="<%= locale.getLanguage() %>">
<head>
<title><%= title %></title>
<meta http-equiv="Content-Type" content="text/html; charset=<%= ENCODING %>" />
<meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=0.5,user-scalable=yes" />
<link rel="icon" type="image/png" href="/favicon.png" />
<meta property="og:title" content="<%= CmsStringUtil.escapeHtml(socialMediaTitle) %>" />
<meta property="og:site_name" content="<%= siteName %>" />
<%
if (!description.isEmpty()) {
    out.println("<meta name=\"description\" content=\"" + description + "\" />");
    out.println("<meta property=\"og:description\" content=\"" + description + "\" />");
    out.println("<meta name=\"twitter:card\" content=\"summary\" />");
    out.println("<meta name=\"twitter:site\" content=\"@NorskPolar\" />");
    out.println("<meta name=\"twitter:title\" content=\"" + CmsStringUtil.escapeHtml(socialMediaTitle) + "\" />");
    out.println("<meta name=\"twitter:description\" content=\"" + CmsStringUtil.trimToSize(description, 180, 10, " ...") + "\" />");
    if (featuredImage != null || cmso.existsResource(featuredImage)) {
        out.println("<meta name=\"twitter:image:src\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, featuredImage.concat("?__scale=w:300,h:300,t:3,q:100")) + "\" />");
        out.println("<meta name=\"og:image\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, featuredImage.concat("?__scale=w:400,h:400,t:3,q:100")) + "\" />");
    }
}

if (canonical != null) {
    out.println("<!-- This page may exist at other URLs, but this is the one true URL: -->");
    out.println("<link rel=\"canonical\" href=\"" + canonical + "\" />");
    out.println("<meta property=\"og:url\" content=\"" + canonical + "\" />");
}
if (!feedUri.isEmpty()) {
    // Do we still use this anywhere? (News etc. maybe?)
    out.println("<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"" + cms.link(feedUri) + "\" />");
}
// Include css files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_CSS, requestFileUri));
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_HEAD_SNIPPET, requestFileUri));

if (pageHasImageGallery) {
    if (!cmso.readPropertyObject(requestFileUri, PROP_HEAD_SNIPPET, false).getValue("").contains(IMAGE_GALLERY_HEAD_SNIPPET)) {
        out.println("<!-- Page has embedded image gallery - including assets: -->");
        cms.includeAny(IMAGE_GALLERY_HEAD_SNIPPET);
        out.println("<!-- Done including image gallery gallery assets -->");
    } else {
        out.println("<!-- Page has embedded image gallery, and includes assets itself -->");
    }
}
%>
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/qtip2/2.1.1/jquery.qtip.min.css") %>" />

<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/2016/base.css") %>" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/2016/navigation.css") %>" />
<link href='https://fonts.googleapis.com/css?family=Open+Sans:400,700,300,300italic,400italic,700italic|Source+Sans+Pro:400,700italic,400italic,200italic,700,200|Merriweather:400,900italic,400italic,300italic,900,300' rel='stylesheet' type='text/css'>
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/2016/smallscreens.css") %>" media="(min-width:310px)" />-->
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/2016/largescreens.css") %>" media="(min-width:801px)" />-->
<% if (true) { %>
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/layout-atomic.css") %>" />-->
<% } %>
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/2016/print.css") %>" media="print" />

<!--[if IE]>
<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/ie.css") %>" rel="stylesheet" type="text/css" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="-1" />
<![endif]-->
<!--[if lte IE 8]>
<script src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/html5.js") %>" type="text/javascript"></script>
<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/ie-non-responsive.css") %>" rel="stylesheet" type="text/css" />
<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/ie8.css") %>" rel="stylesheet" type="text/css" />
<![endif]-->
<!--[if lte IE 7]>
<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/ie7.css") %>" rel="stylesheet" type="text/css" />
<![endif]-->
<!--[if lte IE 6]>
<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/old-ie.css") %>" rel="stylesheet" type="text/css" />
<![endif]-->

<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/modernizr.js") %>"></script>
<!--[if lt IE 9]>
     <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
<![endif]-->
<!--[if gte IE 9]><!-->
     <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js"></script>
<!--<![endif]-->
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.form-defaults.js") %>"></script> 
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.autofill.min.js") %>"></script> 
<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/commons.js?locale=" + loc) %>"></script>-->
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/commons-2-0.js") %>"></script>
<%
if (!portal) {
    //
    // ToDo: 
    //
    // Load this conditionally - it's needed only on a couple of pages!
    // Could probably do the same with autofill, form-defaults & qtip above
%>

<!--<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.rwdImageMaps.min.js") %>"></script>-->
<% 
}
// Include javascript files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_JAVASCRIPT, requestFileUri));
%>
<script type="text/javascript">
$(document).ready(function() {
    // Highslide: Loads only if necessary
    readyHighslide('<%= cms.link("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.css") %>', 
                    '<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/highslide/highslide-full.js") %>',
                    '<%= loc %>'
                    );
    // ToDo: Create similar routines for rwdImageMaps, autofill, form-defaults & qtip
});
</script>
</head>
<body<%= homePage ? " id=\"homepage\" class=\"pageview homepage\"" : " id=\"sitepage\" class=\"pageview sitepage\"" %>>
    <a id="skipnav" tabindex="1" href="#contentstart">Skip navigation</a>
    <div id="jsbox"></div>
    <div class="pageview__part pageview__part--top" id="top">
    <% 
        // Info about the current resource, displayed only to editors (logged in users). 
        //cms.include("../../no.npolar.util/elements/opencms-resource-details.jsp");
    %>
        <header class="header header--primary header--<%= loc %>" id="header">
            
            <div class="header__part" id="header-top">
                <%
                //*
                // Show the "quicklinks" menu.
                // This is a separate menu file, and it uses its own template 
                // file. We pass the menu file's URI to the template.
                try {
                    quickLinksTemplate = cms.getCmsObject().readPropertyObject(QUICKLINKS_MENU_URI, "template-elements", false).getValue();
                    quickLinksParams = new HashMap();
                    quickLinksParams.put("resourceUri", QUICKLINKS_MENU_URI);
                    cms.include(quickLinksTemplate, "list", EDITABLE_MENU, quickLinksParams);
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to include the quicklinks menu (using template '" + quickLinksTemplate + "'): " + e.getMessage() + " -->");
                }
                //*/
                %>
            </div>

            <div class="header__part" id="header-mid">
                    
                    <a class="logo logo--primary" id="identity" href="<%= HOME_URI %>" tabindex="2">
                        <img class="logo__image" src="<%= cms.link(SITE_LOGO_URI) %>" alt="<%= siteName %>" />
                        <span class="logo__text hidden" id="identity-text"><%= siteName.replaceAll("\\s", "&nbsp;") %></span>
                    </a>

                    <!-- navigation + search togglers (small screen) -->
                    <a class="button nav-toggler" id="toggle-nav" tabindex="6" href="#nav">
                        <svg class="icon icon-menu"><use xlink:href="#icon-menu"></use></svg>
                    </a>
                    <a class="button smallscr-only" id="toggle-search" tabindex="3" href="#search-global">
                        <svg class="icon icon-search"><use xlink:href="#icon-search"></use></svg>
                    </a>
                    <%
                    try {
                        // 
                        // Link to alternate language(s)
                        //
                        boolean hideLangOptions = Boolean.valueOf(cmso.readPropertyObject(requestFileUri, PROP_ALT_LANG_LINK_EXCLUDE, true).getValue("false")).booleanValue();
                        if (!hideLangOptions) {
                            // Handle the query string, so we can add it to the language switch link
                            String queryString = cms.getRequest().getQueryString();
                            /* // CANNOT DO THIS, IT FUCKS UP EVERYTHING WHEN USING CATEGORIES....
                            if (queryString != null)
                                queryString = URLDecoder.decode(cms.getRequest().getQueryString(), ENCODING);
                            queryString = queryString == null ? "" : "?".concat(URLEncoder.encode(queryString, ENCODING));
                            // SO WE JUST TAKE CARE OF ANY AMPERSANDS INSTEAD (THE MOST COMMON PROBLEM)
                            */
                            if (queryString != null) {
                                queryString = URLDecoder.decode(cms.getRequest().getQueryString(), ENCODING);
                            }
                            queryString = queryString == null ? "" : "?".concat(queryString.replaceAll("\\&", "&amp;"));

                            // Handle case: Path to alternate version set as request attribute
                            //      This approach is used by e.g. "person", see
                            //      /system/modules/no.npolar.common.person/elements/person.jsp
                            String altPath = null;
                            try {
                                altPath = (String)request.getAttribute(REQUEST_ATTR_ALT_LANG_URI);
                                Locale altLocale = Locale.forLanguageTag(altPath.split("/")[1]);
                                out.println(getAltLangLink(cms, altPath, queryString, altLocale, altLocale.getDisplayLanguage(altLocale)));
                            } catch (Exception e) {
                                // ignore
                            }

                            if (altPath == null) {
                                // No alternate path was set as request attribute => Evaluate sibling(s).

                                // Get a list of all sibling resources that have a different locale than the current resource
                                List<String> altLangUris = cms.getLocaleSiblings(requestFileUri);

                                if (!altLangUris.isEmpty()) {
                                    Iterator<String> itr = altLangUris.iterator();
                                    while (itr.hasNext()) {
                                        String altLangUri = itr.next();

                                        // We don't want to link to any URI that only redirects back to the 
                                        // current page.
                                        String languageSiblingRedir = cmso.readPropertyObject(altLangUri, PROP_REDIR_PERM, true).getValue("");
                                        try {
                                            if (!languageSiblingRedir.isEmpty() ) {
                                                String thisUri = cmso.getSitePath(cmso.readResource(requestFileUri)).replace("index.html", "");
                                                String thatUri = cmso.getSitePath(cmso.readResource(languageSiblingRedir)).replace("index.html", "");
                                                if (thatUri.equals(thisUri)) {
                                                    // Sibling redirects to the current page => Ignore it
                                                    continue;
                                                }
                                            }
                                        } catch (Exception ignore) {}

                                        // Get the URI to the sibling
                                        //String languageSiblingPath = cmso.getSitePath(altLangResource);
                                        // If necessary, modify the URI, so we don't link to any index.html-file
                                        if (altLangUri.endsWith("/index.html")) {
                                            altLangUri = altLangUri.substring(0, altLangUri.lastIndexOf("index.html"));
                                        }
                                        // Get the "locale" property object for the sibling
                                        CmsProperty localeProperty = cmso.readPropertyObject(altLangUri, CmsPropertyDefinition.PROPERTY_LOCALE, true);
                                        if (!localeProperty.isNullProperty()) {
                                            // Get the sibling's locale
                                            Locale languageSiblingLocale = new Locale(localeProperty.getValue());
                                            // Get the language name (display language) for the sibling's locale (in the sibling's own language)
                                            String switchLabel = languageSiblingLocale.getDisplayLanguage(languageSiblingLocale);
                                            // Print the link, capitalize the display language
                                            out.println(getAltLangLink(cms, altLangUri, queryString, languageSiblingLocale, switchLabel));
                                        } else {
                                            // Missing locale on language sibling
                                            //out.println("<!-- Missing locale on language sibling -->");
                                        }
                                    }
                                } else {
                                    // No language siblings
                                    out.println("<!-- No alternate language for this page -->");
                                }
                            }
                        }
                        //cms.include(LANGUAGE_SWITCH); 
                        /*
                        Map langParams = new HashMap();
                        langParams.put("text", "true");
                        cms.include(LANGUAGE_SWITCH, null, false, langParams);
                        //*/
                    } catch (Exception e) { 
                        out.println("\n<!-- error including 'switch language' link: " + e.getMessage() + "\n-->"); 
                    }
                    %>

                    <div id="search-global" class="searchbox global-site-search">
                        <form method="get" action="<%= SERP_URI %>">
                            <label for="query" class="hidden"><%= cms.labelUnicode("label.np.search") %></label>
                            <input type="search" class="query query-input" name="query" id="query" placeholder="<%= cms.labelUnicode("label.np.search") %>" />
                            <button class="search-button" title="<%= cms.labelUnicode("label.np.search") %>" type="submit">
                                <svg class="icon icon-search"><use xlink:href="#icon-search"></use></svg>
                            </button>
                        </form>
                    </div>
                
            </div>

        </header> <!-- #header -->
    
    
        <!-- main menu -->
        <!--<div class="" id="navwrap">-->

            <nav class="nav nav--dropdown nav--primary NOT-nav-colorscheme-dark" id="nav" role="navigation">
                <a class="nav-toggler" id="hide-nav" href="#nonav"><%= LABEL_MENU_HIDE %></a>
                <%
                // ToDo:
                // Fix class and remove ID on list - should be like this:
                // <ul class="nav__items">
                // (#nav_topmenu is NOT used anymore in: base.css, navigation.css, commons-2-0.js)
                
                // Get the path to the menu file and put it in a parameter map
                params = new HashMap();
                params.put("filename", menuFile);
                // Read the property "template-elements" from the menu file. This is the path to the menu template file.
                try {
                    menuTemplate = cms.getCmsObject().readPropertyObject(menuFile, "template-elements", false).getValue();
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to read the template for the menu '" + menuFile + "': " + e.getMessage() + " -->");
                }
                try {
                    cms.include(menuTemplate, "full", EDITABLE_MENU, params);
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to include main navigation (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
                }
                %>
            </nav>

        <!--</div>--><!-- #navwrap -->
    
        <!-- Breadcrumb navigation: -->
        <nav class="nav nav--breadcrumb" id="nav_breadcrumb_wrap">
            <%
            // ToDo:
            // Fix class (and remove ID?) on list - should be like this:
            // <ul class="nav__items list list--h list--tight">
            // or maybe:
            // <ul class="nav__items list list--h list--tight" id="nav_breadcrumb">
            // (ID may be good as js hook - should be renamed tho. As should the <nav>'s ID.)
            
            try {
                cms.include(menuTemplate, "breadcrumb", EDITABLE_MENU, params);
            } catch (Exception e) {
                out.println("<!-- An error occured while trying to include the breadcrumb menu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
            }
            %>
        </nav>
        <!-- Done with breadcrumb navigation -->
        
    </div><!-- #top -->
    
    
    
    
    
    
    
    <main class="clearfix pageview__part pageview__part--content main" id="docwrap">
        <!--<div id="mainwrap">-->
            <%
            //}
            /*          
            if (loc.equalsIgnoreCase("en")) {
                CmsResource requestFileResource = cmso.readResource(requestFileUri);
                if (!requestFileResource.isFolder()) {
                    try {
                        CmsFile requestFile = cmso.readFile(requestFileResource);
                        // build up the xml content instance
                        CmsXmlContent xmlContent = CmsXmlContentFactory.unmarshal(cmso, requestFile);
                        if (!xmlContent.hasLocale(locale)) {
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

                            String onlinePath = OpenCms.getLinkManager().getOnlineLink(cmso, norwegianPath);


                            //out.println("<div class=\"twocol\">");
                            out.println("<article class=\"main-content\">");
                            out.println("<h1>This page has not yet been translated</h1>");
                            out.println("<div class=\"ingress\">We're sorry, this page does not exist in English yet. Please check back at a later time.</div>");
                            if (norwegianPath != null) {
                                out.println("<div class=\"paragraph\">");
                                out.println("<ul>"
                                                + "<li><a target=\"_blank\" href=\"http://translate.google.com/translate?hl=en&sl=no&tl=en&u=" + onlinePath + "\">Let Google translate it from Norwegian</a> or</li>"
                                                + "<li><a href=\"" + cms.link(norwegianPath) + "\">Read the Norwegian version</a></li>"
                                            + "</ul>");
                                out.println("</div>");
                            }
                            //out.println("</div>");
                            out.println("</article>");
                        }
                    } catch (Exception e) {
                       // This is more than likely quite OK, it probably means that the requested file was not of type xmlcontent
                    }
                }
            }
            //*/
            %>
            
            <!--<div id="content">-->
                <a id="contentstart"></a>
                <article class="article article--main main-content<%= (portal ? " portal" : "") %>">
</cms:template>

<cms:template element="contentbody">
	<cms:include element="body" />
</cms:template>

<cms:template element="footer">
                </article>
            <%
            if (!portal) {
                //
                // ToDo:
                //
                // Move this to elsewhere on the page!
                
                //
                // Handle additional navigation.
                // Additional navigation is a right-side menu, and should be 
                // a file of type "resourcelist".
                // This kind of extra navigation is currently used by:
                // - "big events" (events with multiple pages)
                //
                String navAddPath = cmso.readPropertyObject(requestFileUri, "menu-file-additional", true).getValue("");
                if (!navAddPath.isEmpty()) {
                    out.println("<aside>");
                    out.println("<nav class=\"nav nav--microsite\" role=\"navigation\">");
                    cms.includeAny(navAddPath, "resourceUri");
                    out.println("</nav>");
                    out.println("</aside>");
                }
            }
            %>
            <!--</div>--><!-- #content -->
        <!--</div>--><!-- #mainwrap -->
    </main><!-- #docwrap -->
    
    
    
    
    
    
    <footer class="pageview__part pageview__part--bottom footer footer--primary" id="footer">
        <div class="footer__content" id="footer-content">
            <% cms.include(FOOTER_CONTENT); %>
        </div>
    </footer>
                
                
                
                
<%
// Apply timestamps to pages with type "newsbulletin"
if (dr != null && cmso.readResource(requestFileUri).getTypeId() != OpenCms.getResourceManager().getResourceType(RES_TYPE_NEWS_ARTICLE).getTypeId()) {
%>
<script type="text/javascript">
    $(document).ready(function(){
        //$('h1').first().css('color', 'red');
        $('<time id="dlm" class="secondary smalltext" datetime="<%= getDateAsDatetimeAttribute(dr) %>"><i class="icon-arrows-cw"></i><%= cms.label("label.np.lastupdated") + " " + drStr %></time>').insertAfter( $('h1').first() );
        $('h1').first().css('margin-bottom', '0');
    });
</script>
<% } %>
<!--<script type="text/javascript">var switchTo5x=true;</script>-->
<!--<script type="text/javascript" src="http://w.sharethis.com/button/buttons.js"></script>-->
<!--<script type="text/javascript">stLight.options({publisher: "26d6374c-3ba7-4499-8e0a-b33b41b9d5d9", onhover:false});</script>-->
<script type="text/javascript">
    $(document).ready(function(){
        $('#nav_breadcrumb li').append('<svg class="icon icon-play3"><use xlink:href="#icon-arrow-right-bold"></use></svg>');
    });
    if (!Modernizr.svg) {
        $("#identity img").attr({ src : "<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/np-logo-no-text.png") %>", style : "height:76%;" });
    }
</script>
<!-- AddThis Smart Layers BEGIN -->
<!-- Go to http://www.addthis.com/get/smart-layers to customize -->
<script type="text/javascript" src="//s7.addthis.com/js/300/addthis_widget.js#async=1"></script>
<script type="text/javascript">
    var addthis_config = {
        ui_language: '<%= loc %>',
        pubid: 'ra-526fc8381a670e18'
    };
    addthis.layers({
        'theme': 'transparent',
        'share': {
            'position': 'left',
            'services': 'facebook,twitter,email,print,more',
            //'numPreferredServices': 5,
            'desktop': true,
            'mobile': false
        },
        'responsive': {
            'maxWidth': '1080px',
            'minWidth': '0px'
        },
        'mobile': {
            'mobile': false
        }
    });
</script>
    <!-- AddThis Smart Layers END -->
<%
    // Enable Analytics 
// (... but not if the "visitor" is actually a logged-in user)
if (!USER_LOGGED_IN) {
%>
<script type="text/javascript">
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-770196-22', 'auto');
ga('send', 'pageview');
</script>
<script type="text/javascript">
/*
Script: Autogaq 2.1.6 (http://redperformance.no/autogaq/)
Last update: 6 May 2015
Description: Finds external links and track clicks as Events that gets sent to Google Analytics
Compatibility: Google Universal Analytics
*/
!function(){function a(a){var c=a.target||a.srcElement,f=!0,i="undefined"!=typeof c.href?c.href:"",j=i.match(document.domain.split(".").reverse()[1]+"."+document.domain.split(".").reverse()[0]);if(!i.match(/^javascript:/i)){var k=[];if(k.value=0,k.non_i=!1,i.match(/^mailto\:/i))k.category="contact",k.action="email",k.label=i.replace(/^mailto\:/i,""),k.loc=i;else if(i.match(d)){var l=/[.]/.exec(i)?/[^.]+$/.exec(i):void 0;k.category="download",k.action=l[0],k.label=i.replace(/ /g,"-"),k.loc=e+i}else i.match(/^https?\:/i)&&!j?(k.category="outbound traffic",k.action="click",k.label=i.replace(/^https?\:\/\//i,""),k.non_i=!0,k.loc=i):i.match(/^tel\:/i)?(k.category="contact",k.action="telephone",k.label=i.replace(/^tel\:/i,""),k.loc=i):f=!1;f&&(a.preventDefault(),g=k.loc,h=a.target.target,ga("send","event",k.category.toLowerCase(),k.action.toLowerCase(),k.label.toLowerCase(),k.value,{nonInteraction:k.non_i}),b())}}function b(){"_blank"==h?window.open(g,"_blank"):window.location.href=g}function c(a,b,c){a.addEventListener?a.addEventListener(b,c,!1):a.attachEvent("on"+b,function(){return c.call(a,window.event)})}var d=/\.(zip|exe|dmg|pdf|doc.*|xls.*|ppt.*|mp3|txt|rar|wma|mov|avi|wmv|flv|wav)$/i,e="",f=document.getElementsByTagName("base");f.length>0&&"undefined"!=typeof f[0].href&&(e=f[0].href);for(var g="",h="",i=document.getElementsByTagName("a"),j=0;j<i.length;j++)c(i[j],"click",a)}();
</script>
<script type="text/javascript">
/*
Script: Still here beacon (Based on http://redperformance.no/google-analytics/time-on-site-manipulasjon/)
Last update: 3 Nov 2015
Description: Sends an event to Google Analytics every N seconds after the page has loaded, to improve time-on-site metrics.
    Works like a beacon, regularly signaling that the visitor is "still here".
    By changing nonInteraction to false, beacon beeps are treated as interactions. The most notable effect 
    of this will be that any visit that produces at least one beacon beep will not be considered a bounce.
Compatibility: Google Universal Analytics
*/
var secondsOnPage = 0; // How many (active) seconds the user has spent on this page
var pageVisible = true; // Flag that indicates whether or not the page is visible, see http://www.samdutton.com/pageVisibility/
var beaconInterval = 10; // Frequency at which to send the beacon signal (in seconds)
function handleVisibilityChange() {
    try {
        if (document['hidden']) {
            pageVisible = false;
        } else {
            pageVisible = true;
        }
    } catch (err) {
        pageVisible = true;
    }
}
// Set initial page visibility flag
handleVisibilityChange();
// Set the visibility change handler
document.addEventListener('visibilitychange', handleVisibilityChange, false);
// Initialize counter and beacon signal
window.setInterval(
    function() {
        try {
            if (pageVisible) {
                if (++secondsOnPage % beaconInterval === 0) {
                    ga('send', 'event', 'seconds on page', 'log', secondsOnPage, {nonInteraction: true});
                }
            }
        } catch (ignore) { }
    }, 1000);
</script>
<% 
}
// Clear hoverbox resolver
cnr.clear();
// Clear session variables and hoverbox resolver
sess.removeAttribute("share");
sess.removeAttribute("autoRelatedPages");
sess.removeAttribute(ContentNotationResolver.SESS_ATTR_NAME);
// /system/modules/no.npolar.site.npweb/resources/style/np-logo.svg

cms.includeAny("/system/modules/no.npolar.site.npweb/resources/svg/defs.svg");
%>
</body>
</html>
</cms:template>