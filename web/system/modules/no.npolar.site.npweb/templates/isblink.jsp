<%-- 
    Document   : isblink master template. Based on the NPI master template.
    Created on : Nov 16, 2012, 11:28:59 AM
    Author     : flakstad
--%><%@page import="org.opencms.jsp.*,
		org.opencms.file.types.*,
		org.opencms.file.*,
                org.opencms.util.CmsStringUtil,
                org.opencms.util.CmsHtmlExtractor,
                org.opencms.util.CmsRequestUtil,
                org.opencms.security.CmsRoleManager,
                org.opencms.security.CmsRole,
                org.opencms.mail.CmsSimpleMail,
                org.opencms.main.OpenCms,
                org.opencms.xml.content.*,
                org.opencms.db.CmsResourceState,
                org.opencms.flex.CmsFlexController,
		java.util.*,
                java.text.SimpleDateFormat,
                java.text.DateFormat,
                no.npolar.common.menu.*,
                no.npolar.util.CmsAgent,
                no.npolar.util.contentnotation.*"
%><%@taglib prefix="cms" uri="http://www.opencms.org/taglib/cms"
%><%!

/**
 * Gets a date in the datetime attribute format.
 */
private String getDateAsDatetimeAttribute(Date date) {
    SimpleDateFormat dfFullIso = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", new Locale("en"));
    dfFullIso.setTimeZone(TimeZone.getTimeZone("GMT+1"));
    return dfFullIso.format(date);
}

public boolean isAllowedAccess(CmsAgent cms) {
    if (OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER)) {
        // Allow logged-in user
        return true;
    }
    
    HttpServletRequest request = cms.getRequest();
    String ip = request.getRemoteAddr();
    // 158.39.97.128-255, 158.39.97.80-94, 158.39.64 og 65 samt 193.156.10 og 193.156.15
    
    // Troll:
    if (ip.startsWith("158.39.97.")) // Troll
    { 
        String[] ipParts = ip.split("\\.");
        try {
            int ipLast = Integer.parseInt(ipParts[ipParts.length - 1]);
            if (ipLast >= 128 && ipLast <= 255) // These are the specific Troll IPs
                return true;
            else if (ipLast >= 80 && ipLast <= 94) // VPN series
                return true;
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    // Others:
    else if (ip.startsWith("158.39.64.")    // tromsø
            || ip.startsWith("158.39.65.") // tromsø
            || ip.startsWith("193.156.10.") // svalbard
            || ip.startsWith("193.156.15.")) // svalbard
    {
        // All allowed
        return true;
    }
    return false;
}
%><%
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Integer requestFileTypeId   = cmso.readResource(requestFileUri).getTypeId();
boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);

// Redirect HTTPS requests to HTTP for any non-logged in user
if (!loggedInUser && cms.getRequest().isSecure()) {
    String redirAbsPath = "http://" + request.getServerName() + cms.link(requestFileUri);
    String qs = cms.getRequest().getQueryString();
    if (qs != null && !qs.isEmpty()) {
        redirAbsPath += "?" + qs;
    }
    //out.println("<!-- redirect path is '" + redirAbsPath + "' -->");
    //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
    cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
}


// Redirect somewhere?
// This is used for example on Norwegian siblings of events that contains 
// content in English only. We use it so that the event can appear also in 
// Norwegian listings (because a Norwegian sibling exists), but at the same time
// only the English version will ever be accessible (because the Norwegian 
// version redirects to it). 
// This redirect option can help handling event navigation and registration
// forms (if such pages exists), and it is also good for SEO (because there will  
// be no duplicate content).
// IMPORTANT: Setting this property carelessly or incorrectly can cause A LOT of 
// damage to the site, so apply with care!
CmsProperty redirPermProp = cmso.readPropertyObject(requestFileUri, "redirect.permanent", true);
if (!redirPermProp.isNullProperty()) {
    String redirPermPath = redirPermProp.getValue("");
    if (cmso.existsResource(redirPermPath)) {
        String redirAbsPath = "http://" + request.getServerName() + cms.link(redirPermPath);
        String qs = cms.getRequest().getQueryString();
        if (qs != null && !qs.isEmpty()) {
            redirAbsPath += "?" + qs;
        }
        //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
        cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
    } else {
        try {
            // Attempting to redirect to non-existing resource: Send error message.
            CmsSimpleMail errorMail = new CmsSimpleMail();
            errorMail.addTo("nettredaktor@npolar.no");
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

Locale loc                  = cms.getRequestContext().getLocale();
String locale               = loc.toString();
String description          = CmsStringUtil.escapeHtml(CmsHtmlExtractor.extractText(cms.property("Description", requestFileUri, ""), "utf-8"));
String title                = cms.property("Title", requestFileUri, "");
String titleAddOn           = cms.property("Title.addon", "search", "");
String feedUri              = cms.property("rss", requestFileUri, "");
boolean portal              = Boolean.valueOf(cms.property("portalpage", requestFileUri, "false")).booleanValue();
String canonical            = null;
String featuredImage        = null;
String includeFilePrefix    = "";
String fs                   = null; // font size
HttpSession sess            = request.getSession();
String siteName             = cms.property("sitename", "search", cms.label("label.np.sitename"));
//boolean loggedInUser        = OpenCms.getRoleManager().hasRole(cms.getCmsObject(), CmsRole.WORKPLACE_USER);
boolean pinnedNav           = false; 
boolean homePage            = false;
try {
    if (sess.getAttribute("pinned_nav") == null) {
        pinnedNav = true; // Menu ON by default
        //out.println("<!-- menu set to ON -->");
    }
    else {
        pinnedNav = Boolean.parseBoolean((String)sess.getAttribute("pinned_nav"));
        //out.println("<!-- menu state found in session -->");
    }
} catch (Exception e) {
}


// Handle Intranet requests (restrict access)
if (!loggedInUser && cmso.readResource(requestFileUri).getRootPath().startsWith("/sites/isblink/")) {
    if (!requestFileUri.equals("/noaccess.html")) { // Don't hide the "No access" page
        if (!isAllowedAccess(cms)) {
            // CmsRequestUtil.redirectPermanently(cms, "/noaccess.html"); // Bad method, sends 302
            cms.sendRedirect("/noaccess.html", HttpServletResponse.SC_MOVED_TEMPORARILY);
            return;
        }
    }
}


// Redirect requests for np_project resources to the correct URL
try {
    if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("np_project").getTypeId()) {
        String projectId = CmsResource.getName(requestFileUri);
        if (projectId.endsWith(".html"))
            projectId = projectId.substring(0, projectId.length() - ".html".length());
        String detailPageUri = locale.equalsIgnoreCase("no") ? "/no/prosjekter/detaljer" : "/en/projects/details";
        String redirectTargetPath = detailPageUri + "?pid=" + projectId;// e.g. "/en/" to redirect to the localized english folder
        String redirAbsPath = request.getScheme() + "://" + request.getServerName() + redirectTargetPath;
        //CmsRequestUtil.redirectPermanently(cms, redirAbsPath); // Bad method, sends 302
        cms.sendRedirect(redirAbsPath, HttpServletResponse.SC_MOVED_PERMANENTLY);
    }
} catch (Exception e) {
    // oh well ...
}

Date dr = null;
String drStr = null;
try {
    long drLong = cmso.readResource(requestFileUri).getDateReleased();
    dr = drLong > 0 ? new Date(drLong) : null;
    drStr = new SimpleDateFormat(cms.label("label.np.dateformat.normal"), loc).format(dr);
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
    cnr.loadGlobals(cms, "/" + cms.getRequestContext().getLocale() + "/_global/tooltips.html");
    cnr.loadGlobals(cms, "/" + cms.getRequestContext().getLocale() + "/_global/references.html");
    sess.setAttribute(ContentNotationResolver.SESS_ATTR_NAME, cnr);
} catch (Exception e) {
    out.println("<!-- Content notation resolver error: " + e.getMessage() + " -->");
}

homePage = requestFileUri.equals("/" + loc + "/") 
            || requestFileUri.equals("/" + loc + "/index.html")
            || requestFileUri.equals("/" + loc + "/index.jsp");




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

if (!portal) {
    try {
        if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("np_portalpage").getTypeId())
            portal = true;
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Portal page module not installed
    }
}

String[] moreMarkupResourceTypeNames = { 
                                            "np_event"
                                            , "gallery"
                                            , "np_form"
                                            , "faq"
                                            //, "person"
                                            //, "np_eventcal"
                                        };
// Add those filetypes that require extra markup from this template 
// (These will be wrapped in <article class="main-content">)
List moreMarkupResourceTypes= new ArrayList();
for (int iResTypeNames = 0; iResTypeNames < moreMarkupResourceTypeNames.length; iResTypeNames++) {
    try {
        moreMarkupResourceTypes.add(OpenCms.getResourceManager().getResourceType(moreMarkupResourceTypeNames[iResTypeNames]).getTypeId());
    } catch (org.opencms.loader.CmsLoaderException unknownResTypeException) {
        // Resource type not installed
    }
}

// Handle case:
// - Title set as request attribute
if (request.getAttribute("title") != null) {
    try {
        String reqAttrTitle = (String)request.getAttribute("title");
        //out.println("<!-- set title to '" + reqAttrTitle + "' (found request attribute) -->");
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
    if (requestFileTypeId == OpenCms.getResourceManager().getResourceType("person").getTypeId()) {
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
        title = cmso.readPropertyObject(requestFileUri.concat("index.html"), "Title", false).getValue("No title");
    }
}

//boolean isFrontPage = false;
//try { isFrontPage = title.equals(siteName); } 
//catch (Exception e) {}

// Insert the "add-on" to the title. For example: A big event has multiple
// pages, and to make the titles unique, the event name could be used as a title add-on.
// Instead of "Programme - NPI", the title would be "Programme - <event name> - NPI"
if (titleAddOn != null && !titleAddOn.equalsIgnoreCase("none") && !titleAddOn.isEmpty()) {
    title = title.concat(" - ").concat(titleAddOn);
}

if (!homePage) {
    title = title.concat(" - ").concat(siteName);
} else {
    title = siteName;
}

title = CmsHtmlExtractor.extractText(title, "utf-8");

// Done with the title. Now create a version of the title specifically targeted at social media (facebook, twitter etc.)
String socialMediaTitle = title.endsWith((" - ").concat(siteName)) ? title.replace((" - ").concat(siteName), "") : title;
// Featured image set? (Also for social media.)
featuredImage = cmso.readPropertyObject(requestFileUri, "image.thumb", false).getValue(null);

final String MENU_TOP_URL       = includeFilePrefix + "/header-menu.html";
final String QUICKLINKS_MENU_URI= "/menu-quicklinks-isblink.html";
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
%><cms:template element="header"><!DOCTYPE html>
<html lang="<%= loc.getLanguage() %>">
<head>
<title><%= title %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=0.5,user-scalable=yes" />
<link rel="icon" type="image/png" href="/favicon.png" />
<meta property="og:title" content="<%= socialMediaTitle %>" />
<meta property="og:site_name" content="<%= siteName %>" />
<%
if (!description.isEmpty()) {
    out.println("<meta name=\"description\" content=\"" + description + "\" />");
    out.println("<meta property=\"og:description\" content=\"" + description + "\" />");
    out.println("<meta name=\"twitter:card\" content=\"summary\" />");
    out.println("<meta name=\"twitter:site\" content=\"@NorskPolar\" />");
    out.println("<meta name=\"twitter:title\" content=\"" + socialMediaTitle + "\" />");
    out.println("<meta name=\"twitter:description\" content=\"" + CmsStringUtil.trimToSize(description, 180, 10, " ...") + "\" />");
    if (featuredImage != null || cmso.existsResource(featuredImage)) {
        out.println("<meta name=\"twitter:image:src\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, featuredImage.concat("?__scale=w:300,h:300,t:3,q:100")) + "\" />");
        out.println("<meta name=\"og:image\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, featuredImage.concat("?__scale=w:400,h:400,t:3,q:100")) + "\" />");
    }
}
// If a font size parameter was set, add an additional safety measure to prevent this URL from being indexed.
if (fs != null) {
    out.println("<meta name=\"robots\" content=\"noindex\" />");
}
if (canonical != null) {
    out.println("<!-- This page may exist at other URLs, but this is the true URL: -->");
    out.println("<link rel=\"canonical\" href=\"" + canonical + "\" />");
    out.println("<meta property=\"og:url\" content=\"" + OpenCms.getLinkManager().getOnlineLink(cmso, canonical) + "\" />");
}
if (!feedUri.isEmpty()) {
    out.println("<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"" + cms.link(feedUri) + "\" />");
}
// Include css files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_CSS, requestFileUri));
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_HEAD_SNIPPET, requestFileUri));
/*
List<String> css = new ArrayList<String>();
//css.add("//cdnjs.cloudflare.com/ajax/libs/qtip2/2.1.1/jquery.qtip.min.css");
css.add("/system/modules/no.npolar.common.jquery/resources/qtip2/2.1.1/jquery.qtip.min.css");
//css.add("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.css");
css.add("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.css");
//css.add("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-menu.css");
css.add("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-base.css");
css.add("");
css.add("");
css.add("");
css.add("");
css.add("");
css.add("");
css.add("");
//*/
%>
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("//cdnjs.cloudflare.com/ajax/libs/qtip2/2.1.1/jquery.qtip.min.css") %>" />-->
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/qtip2/2.1.1/jquery.qtip.min.css") %>" />
<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.css") %>" />-->
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide.css") %>" />


<!--<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-menu.css") %>" />-->
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-base.css") %>" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-smallscreens.css") %>" media="(min-width:310px)" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-largescreens.css") %>" media="(min-width:801px)" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/layout-atomic.css") %>" />
<link rel="stylesheet" type="text/css" href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/npweb-2014-print.css") %>" media="print" />




<!--<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/menu-dropdown.css") %>" rel="stylesheet" type="text/css" />-->

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
<%
// Include the WAI stylesheet if neccessary
if (sess.getAttribute("fs") != null && !((String)sess.getAttribute("fs")).equalsIgnoreCase("m")) {
%>
<link href="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/wai.css") %>" rel="stylesheet" type="text/css" />
<%
}
%>

<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/modernizr.js") %>"></script>
<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/highslide/highslide-full.js") %>"></script>
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.js</cms:link>"></script>-->
<!--<script type="text/javascript" src="<cms:link>//cdnjs.cloudflare.com/ajax/libs/qtip2/2.1.1/jquery.qtip.min.js</cms:link>"></script>-->
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.qtip.min.js") %>"></script>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.form-defaults.js") %>"></script> 
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.autofill.min.js") %>"></script> 
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.site.npweb/resources/js/jquery.hoverintent.min.js</cms:link>"></script>--><!-- Applies usability bonus for dropdown navigation -->
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/js/commons.js?locale=" + locale) %>"></script>
<%
if (!portal) {
%>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.rwdImageMaps.min.js") %>"></script>
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.common.videoresource/resources/jwplayer/jwplayer.js</cms:link>"></script>-->
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.common.videoresource/resources/jwplayer/swfobject.js</cms:link>"></script>-->
<% 
} 
else {
%>
<script type="text/javascript" src="<%= cms.link("/system/modules/no.npolar.common.jquery/resources/jquery.carouFredSel-6.1.0-packed.js") %>"></script>
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.common.jquery/resources/jquery.sudoSlider.min.js</cms:link>"></script>-->
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.site.npweb/resources/js/sudoslider-init-2012-03-28.js</cms:link>"></script>-->
<%
}
// Include javascript files from property dynamically. Start on the request page and look at all ancestor folders.
out.println(cms.getHeaderElement(CmsAgent.PROPERTY_JAVASCRIPT, requestFileUri));
%>
<!--<script type="text/javascript" src="<cms:link>/system/modules/no.npolar.common.highslide/resources/js/highslide/highslide-settings.js?locale=<%= locale %></cms:link>"></script>-->
<script type="text/javascript">
$(document).ready(function() {
    //$(".addthis_button_tweet").attr('tw:count','none');
    //$(".addthis_button_google_plusone").attr('g:plusone:count','false');
    //$(".addthis_button_facebook_like").attr({ 'fb:like:layout':'button_count', 'fb:like:action':'recommend'});
<%
if (!pinnedNav) {
%>
    $("#nav_top_wrap").hide();
    $("#leftside").hide();
    $("#leftside").css("margin-left", "-500px");
    $("#content").css("width", "100%");
    //$("#nav_sticky").css("border-top", "1px solid #01acf9");
<% } %>
});
</script>
</head>
<body<%= homePage ? " id=\"homepage\"" : " id=\"sitepage\"" %>>
    <%
    //if (false) { 
    if (!loggedInUser) { 
    %>
        <!-- Google Analytics -->
        <script>
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
            ga('create', 'UA-770196-25', 'auto');
            ga('send', 'pageview');
        </script>
    <%}%>
    <!-- requestFileUri: <%=  requestFileUri %> -->
    <a id="skipnav" tabindex="1" href="#contentstart">Skip navigation</a>
    <div id="jsbox"></div>
<% cms.include("../../no.npolar.util/elements/opencms-resource-details.jsp"); // Info about the current resource, displayed only to editors (logged in users). %>
    <header id="header" class="<%= locale %>">
        <div id="header-top">
            <%
            //*
            // Include the "quicklinks" menu file. It uses its own template file. Pass the URI as a parameter
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
        </div><!-- #header-top -->
            
        <div id="header-mid" class="clearfix">
            <div class="fullwidth-centered">
                <a id="identity" href="<%= HOME_URI %>" tabindex="2">
                    <img src="<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/np-logo-no-text.png") %>" alt="<%= siteName %>" />
                    <span id="identity-text"><%= siteName.replaceAll("\\s", "&nbsp;") %></span>
                </a>
            </div><!-- .fullwidth-centered -->
        </div><!-- #header-mid -->
        
        <div id="nav_smallscreen">
            <a id="nav_toggle" class="bluebar-light"><span><span></span></span></a>
        </div>
        <!--<div class="fullwidth-centered" style="position:relative;<%= "" /*sess.getAttribute("pinned_nav") != null ? (Boolean.valueOf((String)sess.getAttribute("pinned_nav")) ? "" : " display:none;") : ""*/ %>">
            <% /*out.println(cms.getContent("/sm-top", "body", loc));*/ %>
        </div>-->

        <div id="nav_sticky">
            <div id="search-tools">
                <div id="search-tools-inner-wrap" class="clearfix">
                    
                    <div id="global-site-tools">
                        <!-- font size and language selectors -->    
                        <!--
                        <div id="fs-switch" class="global-site-tool">
                            <% 
                            //cms.include(FONT_SIZE_SWITCH); 
                            %>
                        </div>
                        -->
                        <div id="lang-switch" class="global-site-tool">
                            <%
                            Map langParams = new HashMap();
                            langParams.put("text", "true");
                            cms.include(LANGUAGE_SWITCH, null, false, langParams);
                            %>
                        </div> 
                    </div>
                        
                        
                    <div id="nav_toggler_wrapper">
                        <a id="nav_toggler"<%= pinnedNav ? " class=\"pinned\"" : "" %> tabindex="5"><span id="navicon"><span></span></span><span><%= locale.equalsIgnoreCase("no") ? "Meny" : "Menu" %></span></a>
                        <!--<a id="nav_pin"<%= pinnedNav ? " class=\"pinned\"" : "" %>></a>-->
                    </div>
                    <div id="searchbox" class="global-site-tool">
                        <% cms.include(SEARCHBOX); %>
                    </div>
                    
                    
                    <!-- Small screen quicklinks: -->
                    <!--<form action="<cms:link>../elements/navigate.jsp</cms:link>" method="get" id="mob_nav_quicklinks">
                        <%
                        // Include the "quicklinks" menu (again, sadly), by calling its own template file and passing the URI to the menu file as a parameter
                        /*try {
                            quickLinksTemplate = cms.getCmsObject().readPropertyObject(QUICKLINKS_MENU_URI, "template-elements", false).getValue();
                            quickLinksParams = new HashMap();
                            quickLinksParams.put("resourceUri", QUICKLINKS_MENU_URI);
                            //out.println("<!-- Smallscreen quicklinks (dropdown instead of list), using '" + quickLinksTemplate +"' -->");
                            cms.include(quickLinksTemplate, "dropdown", EDITABLE_MENU, quickLinksParams);
                        } catch (Exception e) {
                            out.println("<!-- An error occured while trying to include the quicklinks menu (using template '" + quickLinksTemplate + "'): " + e.getMessage() + " -->");
                        }
                        out.flush();*/
                        %>
                    </form>-->
                </div>
            </div>
            <!-- Top-level navigation: -->
            <nav id="nav_top_wrap" class="clearfix"<%= sess.getAttribute("pinned_nav") != null ? (Boolean.valueOf((String)sess.getAttribute("pinned_nav")) ? "" : " style=\"display:none;\"") : "" %>><!-- Main navigation wrapper -->
                <%
                
                //
                // TOP-LEVEL NAVIGATION: 
                //                
                
                // Get the path to the menu file and put it in a parameter map
                params = new HashMap();
                params.put("filename", menuFile);
                // Read the property "template-elements" from the menu file. This is the path to the menu template file.
                try {
                    menuTemplate = cms.getCmsObject().readPropertyObject(menuFile, "template-elements", false).getValue();
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to read the template for the menu '" + menuFile + "': " + e.getMessage() + " -->");
                }
                //out.println("<!-- menu template set to '" + menuTemplate + "' -->");
                
                // Include the "mainmenu" element of the menu template file - pass parameters
                try {
                    //out.println("<div class=\"naviwrap\">");
                    //out.println("<!-- Menu is " + menuFile + " (" + menuTemplate + "[topmenu-dd]) -->");
                    cms.include(menuTemplate, "topmenu-dd", EDITABLE_MENU, params);
                    //out.println("</div>");
                } catch (Exception e) {
                    out.println("<!-- An error occured while trying to include the topmenu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
                }
                %>
            </nav><!-- #nav_top_wrap -->
            <!-- Done with top-level navigation -->
            <!-- Small screen navigation: -->
            <%
            //
            // Small screen navigation
            //
            
            
            
            // Put the path to the menu file in a parameter map
            params = new HashMap();
            params.put("filename", menuFile);
            // Read the property "template-elements" from the menu file. This is the path to the menu template file.
            try {
                menuTemplate = cms.getCmsObject().readPropertyObject(menuFile, "template-elements", false).getValue();
            } catch (Exception e) {
                out.println("<!-- An error occured while trying to read the template for the menu '" + menuFile + "': " + e.getMessage() + " -->");
            }
            out.println("");
            // Include the "submenu-smallscreen" element of the menu template file, pass parameters
            try {
                //out.println("<div class=\"naviwrap\">");
                cms.include(menuTemplate, "submenu_small_screen_full", EDITABLE_MENU, params);
                //out.println("</div>");
            } catch (Exception e) {
                out.println("<!-- An error occured while trying to include the topmenu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
            }
            %>
            <!-- Done with small screen navigation -->
            
        </div><!-- #nav_sticky -->
        
    </header> <!-- #header -->
    
    <div id="docwrap" class="clearfix">
        <!--<a id="feedback-for-url" href="/no/feedback.html">Finner du ikke det du leter etter?</a>-->
        <%
        //if (portal) {
            //out.println("<a id=\"nav_toggler\"><span></span></a>");
        //}
        %>
    <div id="mainwrap">
        <%
        
        
        //
        // Left sidebar navigation (submenu navigation)
        //
        
        //if (!portal) {
            //out.println("<div id=\"leftside\" class=\"" + (portal ? "fourcol-equal portal-nav" : "") + "\">");
        
        
            
            
        
        out.println("<div"
                        + " id=\"leftside\""
                        + " class=\"" + (portal ? " portal-nav" : "") + "\"" 
                        + (sess.getAttribute("pinned_nav") != null ? (Boolean.valueOf((String)sess.getAttribute("pinned_nav")) ? "" : " style=\"display:none;\"") : "")
                    + ">");
        
            
            
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
                cms.include(menuTemplate, "submenu-nested", EDITABLE_MENU, params);
                //out.println("</div>");
            } catch (Exception e) {
                out.println("<!-- An error occured while trying to include the submenu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
            }
            
            out.println("</div><!-- #leftside -->");
            
            out.println("<div id=\"content\"" 
                        + (sess.getAttribute("pinned_nav") != null ? (Boolean.valueOf((String)sess.getAttribute("pinned_nav")) ? "" : " style=\"width:100%;\"") : "")
                        + ">");
            
            
            //
            // Breadcrumb navigation
            //
            if (!homePage) { // Don't include breadcrumb navigation on front page
            %>
            <!-- Breadcrumb navigation: -->
            <nav id="nav_breadcrumb_wrap">
                <%
                // Include the "breadcrumb" element of the menu template file, pass parameters
                try {
                    cms.include(menuTemplate, "breadcrumb", EDITABLE_MENU, params);
                }
                catch (Exception e) {
                    out.println("<!-- An error occured while trying to include the breadcrumb menu (using template '" + menuTemplate + "'): " + e.getMessage() + " -->");
                }
                %>
            </nav>
            <!-- Done with breadcrumb navigation -->
            <a id="contentstart"></a>
            <% } 
            
            if (titleAddOn != null && !titleAddOn.equalsIgnoreCase("none") && !titleAddOn.isEmpty()) {
                // Print add-on title
                //out.println("<span class=\"title-addon\">" + titleAddOn + "</span>");
            }

            if (moreMarkupResourceTypes.contains(requestFileTypeId)) {
                //out.println("<div class=\"twocol\">");
                out.println("<article class=\"main-content\">");
            }
        //}
                    
        if (locale.equalsIgnoreCase("en")) {
            CmsResource requestFileResource = cmso.readResource(requestFileUri);
            if (!requestFileResource.isFolder()) {
                try {
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
        %>
</cms:template>

<cms:template element="contentbody">
	<cms:include element="body" />
</cms:template>

<cms:template element="footer">
            <%
            if (!portal) {
                if (moreMarkupResourceTypes.contains(requestFileTypeId)) {
                    //out.println("</div><!-- .twocol -->");
                    out.println("</article>");
                    
                    //
                    // Handle additional navigation.
                    // Additional navigation is a right-side menu, and should be 
                    // a file of type "resourcelist".
                    // This kind of extra navigation is currently used by:
                    // - "big events" (events with multiple pages)
                    //
                    String navAddPath = cmso.readPropertyObject(requestFileUri, "menu-file-additional", true).getValue("");
                    if (!navAddPath.isEmpty()) {
                            out.println("<div id=\"rightside\" class=\"column small\">");
                        cms.includeAny(navAddPath, "resourceUri");
                        out.println("</div><!-- #rightside -->");
                    }
                }
            }
            out.println("</div><!-- #content -->");
            %>
    </div><!-- #mainwrap -->
    </div><!-- #docwrap -->
    
    <footer id="footer">
        <div id="footer-content">
            <div class="clearfix double layout-group">
                <div class="clearfix boxes">
                    <div class="span1">
                        <%
                        out.println(cms.getContent("/footer-content-1.html", "body", loc));
                        %>
                    </div>
                    <div class="span1">
                        <%
                        //out.println(cms.getContent("/footer-buttons.html", "body", loc)); // THIS DOESN'T WORK, because the editor won't allow empty html elements.
                        cms.include("/" + loc.toString() + "/footer-social-media-buttons.html"); // SO DO THIS instead... -.- (Plain text file, one in each language folder)
                        %>
                    </div>
                </div>
            </div>
        </div>
    </footer>
    <%    
    /*
    //if (request.getAttribute("share") != null && request.getAttribute("share").equals("true")) {
    if (sess.getAttribute("share") != null && sess.getAttribute("share").equals("true")) {
        out.println("<script type=\"text/javascript\">var addthis_config = { ui_language: \"" + locale + "\" }</script>");
        out.println("<script type=\"text/javascript\" src=\"http://s7.addthis.com/js/300/addthis_widget.js#username=xa-4c6ead601f06be40\"></script>"); 
    }
    */ 
    if (dr != null && cmso.readResource(requestFileUri).getTypeId() != OpenCms.getResourceManager().getResourceType("newsbulletin").getTypeId()) { 
    %>
    <script type="text/javascript">
        //$('h1').first().css('color', 'red');
        $('<time id="dlm" class="secondary smalltext" datetime="<%= getDateAsDatetimeAttribute(dr) %>"><i class="icon-arrows-cw"></i><%= cms.label("label.np.lastupdated") + " " + drStr %></time>').insertAfter( $('h1').first() );
        $('h1').first().css('margin-bottom', '0');
    </script>
    <% } %>
    <!--<script type="text/javascript">var switchTo5x=true;</script>-->
    <!--<script type="text/javascript" src="http://w.sharethis.com/button/buttons.js"></script>-->
    <!--<script type="text/javascript">stLight.options({publisher: "26d6374c-3ba7-4499-8e0a-b33b41b9d5d9", onhover:false});</script>-->
    <script type="text/javascript">
        if (Modernizr.svg) {
            $("#identity img").attr({ src : "<%= cms.link("/system/modules/no.npolar.site.npweb/resources/style/np-logo.svg") %>", style : "height:76%;" });
        }
    </script>
    
</body>
</html>
<%
// Clear hoverbox resolver
cnr.clear();
// Clear session variables and hoverbox resolver
sess.removeAttribute("share");
sess.removeAttribute("autoRelatedPages");
sess.removeAttribute(ContentNotationResolver.SESS_ATTR_NAME);
// /system/modules/no.npolar.site.npweb/resources/style/np-logo.svg

%>
</cms:template>